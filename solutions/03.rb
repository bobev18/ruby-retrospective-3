module Graphics
  class Canvas
    attr_reader :width, :height

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
      renderer.render(@width, @height, @points)
    end

    private

    def on_canvas?(x, y)
      x.between?(0, @width) and y.between?(0, @height)
    end
  end

  class Renderers
    class Ascii < Renderers
      def self.render(width, height, points)
        super("@", "-", "\n", width, height, points)
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

      def self.render(width, height, points)
        HTML_HEADER + super("<b></b>", "<i></i>", "<br>", width, height, points) +\
          HTML_FOOTER
      end
    end

    private

    def self.process_row(row)
      row.map { |point| @points.include?(point) ? @pixel_on : @pixel_off }.join
    end

    def self.canvas(width, height)
      0.upto(height - 1).map { |y| 0.upto(width - 1).map { |x| [x, y] } }
    end

    def self.render(on, off, separator, width, height, points)
      @points = points
      @pixel_on  = on
      @pixel_off = off
      self.canvas(width, height).map { |row| self.process_row(row) }.join(separator)
    end
  end

  module Shape
    def eql?(other)
      self == other and self.class == other.class
    end

    def hash
      pixels.hash
    end
  end

  class Point
    attr_reader :x, :y
    include Shape

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
    attr_reader :from, :to
    include Shape

    def initialize(point_a, point_b)
      if (point_a <=> point_b) > 0
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

    def pixels
      delta_x, delta_y = @to.x - @from.x, @to.y - @from.y
      slope = delta_y/delta_x.to_f unless delta_x.zero?
      if slope
        rasterize([delta_x, delta_y].max, slope).map { |x, y| [from.x + x, from.y + y] }
      else
        @from.y.upto(@to.y).map { |y| [@from.x, y] }
      end
    end

    private

    def rasterize(length, slope)
      if slope > 1
        0.upto(length).map { |i| [(i/slope).round, i] }
      else
        0.upto(length).map { |i| [i, (i*slope).round] }
      end
    end
  end

  class Rectangle
    attr_reader :left, :right, :top_left, :top_right, :bottom_right, :bottom_left
    include Shape

    def initialize(point_a, point_b)
      if (point_a <=> point_b) > 0
        @left, @right = point_b, point_a
      else
        @left, @right = point_a, point_b
      end
      determine_corners
    end

    def ==(other)
      @top_left == other.top_left and @bottom_right == other.bottom_right
    end

    def pixels
      [
        [@top_left    , @top_right],
        [@top_right   , @bottom_right],
        [@bottom_right, @bottom_left],
        [@bottom_left , @top_left]
      ].map { |points| Line.new *points }.map(&:pixels).reduce &:+
    end

    private

    def corner_setter top_left, top_right, bottom_right, bottom_left
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