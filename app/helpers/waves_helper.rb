module WavesHelper
  # One ripple, drawn well past the frame on both sides so the drift never
  # exposes an edge. The period is fixed at 400 and the CSS drifts by exactly
  # 400, which is what makes the loop seamless.
  PERIOD = 400
  START  = -800
  FINISH = 3200

  def ripple_path(amplitude:, thickness:)
    top = [ "M#{START},0" ]
    x = START
    while x < FINISH
      top << "C#{x + 100},#{-amplitude} #{x + 200},#{amplitude} #{x + PERIOD},0"
      x += PERIOD
    end

    bottom = []
    x = FINISH
    while x > START
      bottom << "C#{x - 100},#{thickness + amplitude} #{x - 200},#{thickness - amplitude} #{x - PERIOD},#{thickness}"
      x -= PERIOD
    end

    "#{top.join(' ')} L#{FINISH},#{thickness} #{bottom.join(' ')} Z"
  end
end
