module Graphics
  class Canvas
    attr_reader :width, :height, :points

    def initialize(width, height)
      @width = width
      @height = height
      @points = []
    end

    def set_pixel(x, y)
      if on_canvas?(x, y)
        @points << [x, y]
      end
    end

    def pixel_at?(x, y)
      if on_canvas?(x, y)
        @points.include? [x, y]
      end
    end

    def draw(shape)
      @points += shape.pixels
    end

    def render_as(renderer)
      renderer.new(self).render
    end

    private

    def on_canvas?(x, y)
      x.between?(0, @width) and y.between?(0, @height)
    end
  end

  class Renderers
    class Ascii < Renderers
      def render
        super("@", "-", "\n")
      end
    end

    class Html < Renderers
      HTML_HEADER = <<-PREDATA
      <!DOCTYPE html>
      <html>
      <head>
        <title>Rendered Canvas</title>
        <style type="text/css">
          .canvas {
            font-size: 1px;
            line-height: 1px;
          }
          .canvas * {
            display: inline-block;
            width: 10px;
            height: 10px;
            border-radius: 5px;
          }
          .canvas i {
            background-color: #eee;
          }
          .canvas b {
            background-color: #333;
          }
        </style>
      </head>
      <body>
        <div class="canvas">
      PREDATA

      HTML_FOOTER = <<-POSTDATA
        </div>
      </body>
      </html>
      POSTDATA

      def render
        HTML_HEADER + super("<b></b>", "<i></i>", "<br>") + HTML_FOOTER
      end
    end

    def initialize(canvas)
      @width = canvas.width
      @height = canvas.height
      @points = canvas.points
    end

    def render(on, off, separator)
      @pixel_on  = on
      @pixel_off = off
      canvas.map { |row| process_row(row) }.join(separator)
    end

    private

    def process_row(row)
      row.map { |point| @points.include?(point) ? @pixel_on : @pixel_off }.join
    end

    def canvas
      0.upto(@height.pred).map { |y| 0.upto(@width.pred).map { |x| [x, y] } }
    end
  end

  module Hashing
    def hash
      pixels.hash
    end
  end

  class Point
    include Hashing
    include Comparable
    attr_reader :x, :y

    def initialize(x, y)
      @x = x
      @y = y
    end

    def pixels
      [[@x, @y]]
    end

    def ==(other)
      @x == other.x and @y == other.y
    end

    alias eql? ==

    def <=>(other)
      result = @x <=> other.x
      if result == 0
        @y <=> other.y
      else
        result
      end
    end
  end

  class Line
    include Hashing
    attr_reader :from, :to

    def initialize(point_a, point_b)
      if point_a > point_b
        @from = point_b
        @to   = point_a
      else
        @from = point_a
        @to   = point_b
      end
    end

    def ==(other)
      @from == other.from and @to == other.to
    end

    alias eql? ==

    def pixels
      delta_x, delta_y = @to.x - @from.x, @to.y - @from.y
      slope = delta_y / delta_x.to_f unless delta_x.zero?

      if slope
        rasterize([delta_x, delta_y].max, slope).map { |x, y| [from.x + x, from.y + y] }
      else
        @from.y.upto(@to.y).map { |y| [@from.x, y] }
      end
    end

    private

    def rasterize(length, slope)
      if slope > 1
        0.upto(length).map { |i| [(i / slope).round, i] }
      else
        0.upto(length).map { |i| [i, (i * slope).round] }
      end
    end
  end

  class Rectangle
    include Hashing
    attr_reader :left, :right, :top_left, :top_right, :bottom_right, :bottom_left

    def initialize(point_a, point_b)
      if point_a > point_b
        @left, @right = point_b, point_a
      else
        @left, @right = point_a, point_b
      end
      determine_corners
    end

    def ==(other)
      @top_left == other.top_left and @bottom_right == other.bottom_right
    end

    alias eql? ==

    def pixels
      [
        [@top_left    , @top_right],
        [@top_right   , @bottom_right],
        [@bottom_right, @bottom_left],
        [@bottom_left , @top_left]
      ].map { |a, b| Line.new a, b }.map(&:pixels).reduce &:+
    end

    private

    def corner_setter(top_left, top_right, bottom_right, bottom_left)
      @top_left     = top_left
      @top_right    = top_right
      @bottom_right = bottom_right
      @bottom_left  = bottom_left
    end

    def determine_corners
      other_left  = Point.new @left.x, @right.y
      other_right = Point.new @right.x, @left.y
      if @left.y < other_left.y
        corner_setter @left, other_right, @right, other_left
      else
        corner_setter other_left, @right, other_right, @left
      end
    end
  end
end