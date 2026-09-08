#pragma once

#include <QColor>
#include <QQuickFramebufferObject>

// Renders the NCS visualizer from spicetify-visualizer with its original
// four-pass GPU pipeline:
//
//   particle  -- an n*n RG32F texture of dot positions
//   dot       -- those positions splatted as instanced quads, MAX-blended
//   blur      -- separable gaussian, two passes
//   finalize  -- max(blurred, dots), tinted
//
// The applet keeps the motion model in QML and feeds the result in through
// `amplitude` and `noiseOffset`, which is what the original's playback-position
// driven code supplies.
class NcsVisualizer : public QQuickFramebufferObject
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(qreal amplitude READ amplitude WRITE setAmplitude NOTIFY amplitudeChanged)
    Q_PROPERTY(qreal noiseOffset READ noiseOffset WRITE setNoiseOffset NOTIFY noiseOffsetChanged)
    Q_PROPERTY(QColor color READ color WRITE setColor NOTIFY colorChanged)
    Q_PROPERTY(QColor glowColor READ glowColor WRITE setGlowColor NOTIFY glowColorChanged)
    Q_PROPERTY(int dotCount READ dotCount WRITE setDotCount NOTIFY dotCountChanged)
    Q_PROPERTY(int seed READ seed WRITE setSeed NOTIFY seedChanged)
    Q_PROPERTY(qreal dotScale READ dotScale WRITE setDotScale NOTIFY dotScaleChanged)
    Q_PROPERTY(qreal glowScale READ glowScale WRITE setGlowScale NOTIFY glowScaleChanged)
    Q_PROPERTY(QString error READ error NOTIFY errorChanged)

public:
    explicit NcsVisualizer(QQuickItem *parent = nullptr);

    Renderer *createRenderer() const override;

    qreal amplitude() const { return m_amplitude; }
    void setAmplitude(qreal v);

    qreal noiseOffset() const { return m_noiseOffset; }
    void setNoiseOffset(qreal v);

    QColor color() const { return m_color; }
    void setColor(const QColor &v);

    QColor glowColor() const { return m_glowColor; }
    void setGlowColor(const QColor &v);

    int dotCount() const { return m_dotCount; }
    void setDotCount(int v);

    int seed() const { return m_seed; }
    void setSeed(int v);

    qreal dotScale() const { return m_dotScale; }
    void setDotScale(qreal v);

    qreal glowScale() const { return m_glowScale; }
    void setGlowScale(qreal v);

    QString error() const { return m_error; }
    // called from the render thread once, guarded by the sync point
    void reportError(const QString &message);

Q_SIGNALS:
    void amplitudeChanged();
    void noiseOffsetChanged();
    void colorChanged();
    void glowColorChanged();
    void dotCountChanged();
    void seedChanged();
    void dotScaleChanged();
    void glowScaleChanged();
    void errorChanged();

private:
    qreal m_amplitude = 0.15;
    qreal m_noiseOffset = 0.0;
    QColor m_color = QColor(QStringLiteral("#ff2e88"));
    QColor m_glowColor = QColor(QStringLiteral("#ff2e88"));
    int m_dotCount = 322;
    int m_seed = 1234;
    qreal m_dotScale = 1.0;
    qreal m_glowScale = 1.0;
    QString m_error;
};
