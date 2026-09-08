#include "ncsvisualizer.h"
#include "shaders.h"

#include <QOpenGLBuffer>
#include <QOpenGLContext>
#include <QOpenGLExtraFunctions>
#include <QOpenGLFramebufferObject>
#include <QOpenGLFramebufferObjectFormat>
#include <QOpenGLShaderProgram>
#include <QOpenGLVertexArrayObject>
#include <QVector2D>
#include <QVector3D>
#include <QtMath>

namespace
{

// Matches the original: uSphereRadius = mapLinear(amp, 0, 1, 0.75 * 0.9, 0.9)
qreal sphereRadiusFor(qreal amplitude)
{
    return 0.75 * 0.9 + amplitude * (0.9 - 0.75 * 0.9);
}

class NcsRenderer : public QQuickFramebufferObject::Renderer, protected QOpenGLExtraFunctions
{
public:
    NcsRenderer() = default;

    ~NcsRenderer() override
    {
        delete m_particleFbo;
        delete m_dotFbo;
        delete m_blurXFbo;
        delete m_blurYFbo;
    }

    QOpenGLFramebufferObject *createFramebufferObject(const QSize &size) override
    {
        QOpenGLFramebufferObjectFormat format;
        format.setInternalTextureFormat(GL_RGBA8);
        format.setSamples(0);
        return new QOpenGLFramebufferObject(size, format);
    }

    void synchronize(QQuickFramebufferObject *item) override
    {
        auto *viz = static_cast<NcsVisualizer *>(item);
        m_amplitude = viz->amplitude();
        m_noiseOffset = viz->noiseOffset();
        m_color = viz->color();
        m_glowColor = viz->glowColor();
        m_dotCount = qBound(2, viz->dotCount(), 1024);
        m_seed = viz->seed();
        m_dotScale = viz->dotScale();
        m_glowScale = viz->glowScale();

        if (!m_pendingError.isEmpty()) {
            viz->reportError(m_pendingError);
            m_pendingError.clear();
        }
    }

    void render() override;

private:
    bool initialize();
    bool buildProgram(QOpenGLShaderProgram &program, const char *vert, const char *frag, const char *name);
    void ensureTargets(int viewportSize);
    void drawQuad(QOpenGLShaderProgram &program);

    bool m_initialized = false;
    bool m_failed = false;
    QString m_pendingError;

    qreal m_amplitude = 0.15;
    qreal m_noiseOffset = 0.0;
    QColor m_color;
    QColor m_glowColor;
    int m_dotCount = 322;
    int m_seed = 1234;
    qreal m_dotScale = 1.0;
    qreal m_glowScale = 1.0;

    int m_targetSize = 0;
    int m_particleSize = 0;

    QOpenGLShaderProgram m_particleProgram;
    QOpenGLShaderProgram m_dotProgram;
    QOpenGLShaderProgram m_blurProgram;
    QOpenGLShaderProgram m_finalizeProgram;

    QOpenGLBuffer m_quad{QOpenGLBuffer::VertexBuffer};
    QOpenGLVertexArrayObject m_vao;

    QOpenGLFramebufferObject *m_particleFbo = nullptr;
    QOpenGLFramebufferObject *m_dotFbo = nullptr;
    QOpenGLFramebufferObject *m_blurXFbo = nullptr;
    QOpenGLFramebufferObject *m_blurYFbo = nullptr;
};

bool NcsRenderer::buildProgram(QOpenGLShaderProgram &program, const char *vert, const char *frag, const char *name)
{
    if (!program.addShaderFromSourceCode(QOpenGLShader::Vertex, vert)) {
        m_pendingError = QStringLiteral("Failed to compile the %1 vertex shader:\n%2").arg(QLatin1String(name), program.log());
        return false;
    }
    if (!program.addShaderFromSourceCode(QOpenGLShader::Fragment, frag)) {
        m_pendingError = QStringLiteral("Failed to compile the %1 fragment shader:\n%2").arg(QLatin1String(name), program.log());
        return false;
    }
    if (!program.link()) {
        m_pendingError = QStringLiteral("Failed to link the %1 shader:\n%2").arg(QLatin1String(name), program.log());
        return false;
    }
    return true;
}

bool NcsRenderer::initialize()
{
    if (m_initialized) {
        return !m_failed;
    }
    m_initialized = true;
    initializeOpenGLFunctions();

    QOpenGLContext *ctx = QOpenGLContext::currentContext();
    if (!ctx || ctx->isOpenGLES()) {
        m_pendingError = QStringLiteral("The NCS renderer needs desktop OpenGL 3.3 or newer.");
        m_failed = true;
        return false;
    }
    const QSurfaceFormat fmt = ctx->format();
    if (fmt.majorVersion() * 10 + fmt.minorVersion() < 33) {
        m_pendingError = QStringLiteral("The NCS renderer needs OpenGL 3.3 or newer (got %1.%2).").arg(fmt.majorVersion()).arg(fmt.minorVersion());
        m_failed = true;
        return false;
    }

    if (!buildProgram(m_particleProgram, kParticleVert, kParticleFrag, "particle")
        || !buildProgram(m_dotProgram, kDotVert, kDotFrag, "dot")
        || !buildProgram(m_blurProgram, kBlurVert, kBlurFrag, "blur")
        || !buildProgram(m_finalizeProgram, kFinalizeVert, kFinalizeFrag, "finalize")) {
        m_failed = true;
        return false;
    }

    // A VAO is mandatory in a core profile, and the scene graph does not leave
    // one bound for us.
    m_vao.create();
    m_vao.bind();

    static const GLfloat quad[] = {-1, -1, -1, 1, 1, 1, 1, -1};
    m_quad.create();
    m_quad.bind();
    m_quad.allocate(quad, sizeof(quad));
    m_quad.release();
    m_vao.release();

    return true;
}

void NcsRenderer::ensureTargets(int viewportSize)
{
    if (m_particleSize != m_dotCount) {
        m_particleSize = m_dotCount;
        delete m_particleFbo;
        QOpenGLFramebufferObjectFormat format;
        format.setInternalTextureFormat(GL_RG32F);
        m_particleFbo = new QOpenGLFramebufferObject(QSize(m_dotCount, m_dotCount), format);
        glBindTexture(GL_TEXTURE_2D, m_particleFbo->texture());
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }

    if (m_targetSize == viewportSize) {
        return;
    }
    m_targetSize = viewportSize;

    delete m_dotFbo;
    delete m_blurXFbo;
    delete m_blurYFbo;

    QOpenGLFramebufferObjectFormat format;
    format.setInternalTextureFormat(GL_R8);
    const QSize size(viewportSize, viewportSize);
    m_dotFbo = new QOpenGLFramebufferObject(size, format);
    m_blurXFbo = new QOpenGLFramebufferObject(size, format);
    m_blurYFbo = new QOpenGLFramebufferObject(size, format);

    // The X blur is the only one sampled at non-texel offsets, so it is the
    // only one that wants linear filtering -- as in the original.
    for (auto *fbo : {m_dotFbo, m_blurXFbo, m_blurYFbo}) {
        const GLint filter = (fbo == m_blurXFbo) ? GL_LINEAR : GL_NEAREST;
        glBindTexture(GL_TEXTURE_2D, fbo->texture());
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, filter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, filter);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
        glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    }
}

void NcsRenderer::drawQuad(QOpenGLShaderProgram &program)
{
    m_quad.bind();
    const int loc = program.attributeLocation("inPosition");
    program.enableAttributeArray(loc);
    program.setAttributeBuffer(loc, GL_FLOAT, 0, 2);
    glDrawArrays(GL_TRIANGLE_FAN, 0, 4);
    m_quad.release();
}

void NcsRenderer::render()
{
    if (!initialize()) {
        return;
    }

    const QSize fboSize = framebufferObject()->size();
    const int viewportSize = qMax(2, qMin(fboSize.width(), fboSize.height()));
    ensureTargets(viewportSize);

    m_vao.bind();

    const float amplitude = float(qBound(0.0, m_amplitude, 1.0));
    const int dotCount = m_dotCount;
    const float dotRadius = 0.9f / float(dotCount) * float(m_dotScale);
    const float dotRadiusPx = dotRadius * 0.5f * float(viewportSize);
    const float sphereRadius = float(sphereRadiusFor(amplitude));
    const float feather = float(qPow(amplitude + 3.0, 2.0) * (45.0 / 1568.0));

    // --- particle positions ------------------------------------------------
    glDisable(GL_BLEND);
    m_particleFbo->bind();
    glViewport(0, 0, dotCount, dotCount);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    m_particleProgram.bind();
    m_particleProgram.setUniformValue("uNoiseOffset", float(m_noiseOffset));
    m_particleProgram.setUniformValue("uAmplitude", amplitude);
    m_particleProgram.setUniformValue("uSeed", m_seed);
    m_particleProgram.setUniformValue("uDotSpacing", 0.9f);
    m_particleProgram.setUniformValue("uDotOffset", -0.9f / 2.0f);
    m_particleProgram.setUniformValue("uSphereRadius", sphereRadius);
    m_particleProgram.setUniformValue("uFeather", feather);
    m_particleProgram.setUniformValue("uNoiseFrequency", 4.0f);
    m_particleProgram.setUniformValue("uNoiseAmplitude", float(0.32 * 0.9));
    drawQuad(m_particleProgram);
    m_particleProgram.release();

    // --- splat the dots ----------------------------------------------------
    glEnable(GL_BLEND);
    glBlendEquation(GL_MAX);
    m_dotFbo->bind();
    glViewport(0, 0, viewportSize, viewportSize);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);

    m_dotProgram.bind();
    m_dotProgram.setUniformValue("uDotCount", dotCount);
    m_dotProgram.setUniformValue("uDotRadius", dotRadius);
    m_dotProgram.setUniformValue("uDotRadiusPX", dotRadiusPx);
    m_dotProgram.setUniformValue("uParticleTexture", 0);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_particleFbo->texture());

    m_quad.bind();
    const int dotPosLoc = m_dotProgram.attributeLocation("inPosition");
    m_dotProgram.enableAttributeArray(dotPosLoc);
    m_dotProgram.setAttributeBuffer(dotPosLoc, GL_FLOAT, 0, 2);
    glDrawArraysInstanced(GL_TRIANGLE_FAN, 0, 4, dotCount * dotCount);
    m_quad.release();
    m_dotProgram.release();

    // --- separable blur ----------------------------------------------------
    m_blurProgram.bind();
    m_blurProgram.setUniformValue("uBlurRadius", float(0.01 * viewportSize * m_glowScale));
    m_blurProgram.setUniformValue("uInputTexture", 0);

    m_blurXFbo->bind();
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    m_blurProgram.setUniformValue("uBlurDirection", QVector2D(1.0f / viewportSize, 0.0f));
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_dotFbo->texture());
    drawQuad(m_blurProgram);

    m_blurYFbo->bind();
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    m_blurProgram.setUniformValue("uBlurDirection", QVector2D(0.0f, 1.0f / viewportSize));
    glBindTexture(GL_TEXTURE_2D, m_blurXFbo->texture());
    drawQuad(m_blurProgram);
    m_blurProgram.release();

    // --- composite into the item's own framebuffer -------------------------
    framebufferObject()->bind();
    glDisable(GL_BLEND);
    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    // centre the square result if the item is not exactly square
    glViewport((fboSize.width() - viewportSize) / 2, (fboSize.height() - viewportSize) / 2, viewportSize, viewportSize);

    m_finalizeProgram.bind();
    m_finalizeProgram.setUniformValue("uOutputColor", QVector3D(m_color.redF(), m_color.greenF(), m_color.blueF()));
    m_finalizeProgram.setUniformValue("uGlowColor", QVector3D(m_glowColor.redF(), m_glowColor.greenF(), m_glowColor.blueF()));
    m_finalizeProgram.setUniformValue("uBlurredTexture", 0);
    m_finalizeProgram.setUniformValue("uOriginalTexture", 1);
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, m_blurYFbo->texture());
    glActiveTexture(GL_TEXTURE1);
    glBindTexture(GL_TEXTURE_2D, m_dotFbo->texture());
    drawQuad(m_finalizeProgram);
    m_finalizeProgram.release();

    glActiveTexture(GL_TEXTURE0);
    m_vao.release();

    // Leave the pipeline as the scene graph expects to find it.
    glBlendEquation(GL_FUNC_ADD);
    glDisable(GL_BLEND);
}

} // namespace

NcsVisualizer::NcsVisualizer(QQuickItem *parent)
    : QQuickFramebufferObject(parent)
{
    setMirrorVertically(true);
}

QQuickFramebufferObject::Renderer *NcsVisualizer::createRenderer() const
{
    return new NcsRenderer;
}

void NcsVisualizer::setAmplitude(qreal v)
{
    if (m_amplitude == v) {
        return;
    }
    m_amplitude = v;
    Q_EMIT amplitudeChanged();
    update();
}

void NcsVisualizer::setNoiseOffset(qreal v)
{
    if (m_noiseOffset == v) {
        return;
    }
    m_noiseOffset = v;
    Q_EMIT noiseOffsetChanged();
    update();
}

void NcsVisualizer::setColor(const QColor &v)
{
    if (m_color == v) {
        return;
    }
    m_color = v;
    Q_EMIT colorChanged();
    update();
}

void NcsVisualizer::setGlowColor(const QColor &v)
{
    if (m_glowColor == v) {
        return;
    }
    m_glowColor = v;
    Q_EMIT glowColorChanged();
    update();
}

void NcsVisualizer::setDotCount(int v)
{
    v = qBound(2, v, 1024);
    if (m_dotCount == v) {
        return;
    }
    m_dotCount = v;
    Q_EMIT dotCountChanged();
    update();
}

void NcsVisualizer::setSeed(int v)
{
    if (m_seed == v) {
        return;
    }
    m_seed = v;
    Q_EMIT seedChanged();
    update();
}

void NcsVisualizer::setDotScale(qreal v)
{
    if (m_dotScale == v) {
        return;
    }
    m_dotScale = v;
    Q_EMIT dotScaleChanged();
    update();
}

void NcsVisualizer::setGlowScale(qreal v)
{
    if (m_glowScale == v) {
        return;
    }
    m_glowScale = v;
    Q_EMIT glowScaleChanged();
    update();
}

void NcsVisualizer::reportError(const QString &message)
{
    if (m_error == message) {
        return;
    }
    m_error = message;
    Q_EMIT errorChanged();
}
