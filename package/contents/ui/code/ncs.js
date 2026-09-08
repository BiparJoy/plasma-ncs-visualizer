.pragma library

// What drives the visualizer.
//
// Upstream is fed by Spotify's audio analysis: it knows the track's whole
// loudness curve up front, and derives the two uniforms from it as
//
//     uAmplitude   = sampleAmplitudeMovingAverage(curve, t, 0.15)
//     uNoiseOffset = (0.5 * t + integral(curve, t)) * 75 * 0.01
//
// so the amplitude is a plain 0.15 s moving average -- no spring, no beat
// detection -- and the noise advances at 0.75 * (0.5 + amplitude).
// MODEL_ORIGINAL reproduces exactly that from CAVA's live loudness.
//
// MODEL_AURORA is the alternative from the Aurora player: a spring for the body
// of the motion plus a transient detector that punches on each beat. It reacts
// harder, at the cost of not being what upstream does.

var MODEL_ORIGINAL = 0;
var MODEL_AURORA = 1;

function createMotion() {
    // Trailing box filter standing in for upstream's centred moving average --
    // we cannot look ahead at live audio.
    var hist = [];
    var histSum = 0;
    var histTime = 0;

    const m = {
        model: MODEL_ORIGINAL,

        // --- MODEL_ORIGINAL ----------------------------------------------
        averageWindow: 0.15,   // upstream's 0.15 s window
        flowSpeed: 1.0,        // multiplier on upstream's noise rate

        // --- MODEL_AURORA ------------------------------------------------
        bodyStiffness: 20,     // spring: higher = snappier body
        bodyDamping: 0.85,     // <1 = momentum/overshoot, 1 = critically damped
        levelSmooth: 6.5,      // how fast the body target follows loudness
        punch: 0.5,            // beat pop strength
        beatDecay: 7.0,        // higher = shorter/snappier beat
        onset: 1.18,           // bass must exceed movingAvg*this to fire a beat

        // --- state --------------------------------------------------------
        amp: 0.15,
        vel: 0,
        smoothTarget: 0.15,
        amplitude: 0.15,       // -> uAmplitude
        noiseOffset: 0,        // -> uNoiseOffset
        beat: 0,
        bassAvg: 0,
        cooldown: 0,
        level: 0.15,
        bass: 0
    };

    function movingAverage(dt, level) {
        hist.push(dt, level);
        histSum += dt * level;
        histTime += dt;
        while (histTime > m.averageWindow && hist.length > 2) {
            const d = hist.shift();
            const v = hist.shift();
            histSum -= d * v;
            histTime -= d;
        }
        return histTime > 0 ? histSum / histTime : level;
    }

    m.setAudio = function (level, bass) {
        m.level = Math.min(1, Math.max(0, level));
        m.bass = Math.min(1, Math.max(0, bass));
    };

    m.update = function (dt) {
        dt = Math.min(dt, 1 / 30);

        if (m.model === MODEL_ORIGINAL) {
            m.amplitude = movingAverage(dt, m.level);
            // upstream: d/dt of (0.5 * t + integral(amplitude)) * 75 * 0.01
            m.noiseOffset += dt * 0.75 * (0.5 + m.amplitude) * m.flowSpeed;
            // keep the other model's state coherent in case it is switched on
            m.amp = m.amplitude;
            m.smoothTarget = m.amplitude;
            m.beat = 0;
            return;
        }

        m.beat *= Math.exp(-dt * m.beatDecay);
        m.bassAvg += (m.bass - m.bassAvg) * Math.min(1, dt * 3);
        m.cooldown -= dt;
        if (m.bass > m.bassAvg * m.onset + 0.015 && m.bass > 0.08 && m.cooldown <= 0) {
            m.beat = 1;
            m.cooldown = 0.11;
        }

        m.smoothTarget += (m.level - m.smoothTarget) * Math.min(1, dt * m.levelSmooth);
        const k = m.bodyStiffness;
        const c = 2 * Math.sqrt(k) * m.bodyDamping;
        const a = k * (m.smoothTarget - m.amp) - c * m.vel;
        m.vel += a * dt;
        m.amp = Math.min(1, Math.max(0, m.amp + m.vel * dt));

        m.amplitude = Math.min(1, m.amp + m.punch * m.beat);
        m.noiseOffset += dt * (0.05 + 2.6 * m.amp + 4.5 * m.beat) * m.flowSpeed;
    };

    return m;
}

// CAVA hands us a bar spectrum; we need a single loudness, plus a bass reading
// for MODEL_AURORA's onset detection.
//
// In stereo, CAVA lays the bars out as [left reversed | right forward], so the
// two channels' low frequencies meet either side of the centre rather than
// sitting at index 0. Verified by correlating the two halves (r = +0.71 as-is,
// +0.97 with the left half reversed) and against a simultaneous mono capture's
// bass bars, whose best-tracking stereo bars were 14-17 of 32.
function analyseBars(values, maxRange, gain, stereo) {
    const n = values.length;
    if (n === 0) {
        return { level: 0, bass: 0 };
    }
    const inv = 1 / Math.max(1, maxRange);

    let sum = 0;
    for (let i = 0; i < n; i++) {
        const v = values[i] * inv;
        sum += v * v;
    }
    const level = Math.min(1, Math.sqrt(sum / n) * 1.9 * gain);

    // lowest ~18% of the spectrum
    const span = Math.max(1, Math.round(n * 0.18));
    let lo, hi;
    if (stereo) {
        const mid = n >> 1;
        const half = Math.max(1, Math.round(span / 2));
        lo = Math.max(0, mid - half);
        hi = Math.min(n, mid + half);
    } else {
        lo = 0;
        hi = span;
    }

    let bs = 0;
    for (let i = lo; i < hi; i++) {
        bs += values[i] * inv;
    }
    const bass = Math.min(1, (bs / (hi - lo)) * 1.5 * gain);
    return { level: level, bass: bass };
}
