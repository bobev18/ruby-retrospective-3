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
      rendition = renderer.new @width, @height, @points
      rendition.process
    end

    private

    def on_canvas?(x, y)
      x.between?(0, @width) and y.between?(0, @height)
    end
  end

  class Renderers

    def initialize(width, height, points)
      @width = width
      @height = height
      @points = points
    end

    class Ascii < Renderers
      def process
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

      def process
        HTML_HEADER + super("<b></b>", "<i></i>", "<br>") +\
          HTML_FOOTER
      end
    end

    private

    def process_row(row)
      row.map { |point| @points.include?(point) ? @pixel_on : @pixel_off }.join
    end

    def canvas
      0.upto(@height - 1).map { |y| 0.upto(@width - 1).map { |x| [x, y] } }
    end

    def process(on, off, separator)
      @pixel_on  = on
      @pixel_off = off
      canvas.map { |row| process_row(row) }.join(separator)
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
    include Shape
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

    def <=>(other)
      result = @x <=> other.x
      if result == 0
        @y <=> other.y
      else
        result
      end
    end

    def to_s
      @x.to_s + ',' + @y.to_s
    end
  end

  class Line
    include Shape
    attr_reader :from, :to

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

      if delta_x != 0
        slope = delta_y/delta_x.to_f
      end

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
    include Shape
    attr_reader :left, :right, :top_left, :top_right, :bottom_right, :bottom_left

    def initialize(point_a, point_b)
      puts "pab #{@point_a} #{@point_b}"
      if (point_a <=> point_b) > 0
        @left  = point_b
        @right = point_a
      else
        @left  = point_a
        @right = point_b
      end
      puts "lr #{@left} #{@right}"
      determine_corners
    end

    def ==(other)
      @top_left == other.top_left and @bottom_right == other.bottom_right
    end

    def pixels
      puts "tl #{@top_left}"
      z = [
        [@top_left    , @top_right],
        [@top_right   , @bottom_right],
        [@bottom_right, @bottom_left],
        [@bottom_left , @top_left]
      ]
      z.each { |zz| puts "#{zz[0]}, #{zz[1]}"}
      z = z.map { |p| Line.new(*p) }
      #.map(&:pixels).reduce &:+
      z.each { |zz| puts "#{zz.from}, #{zz.to}"}
      z.map(&:pixels).reduce &:+
    end

    private

    def corners=(top_left, top_right, bottom_right, bottom_left)
      puts "corners #{top_left} #{top_right} #{bottom_right} #{bottom_left}"
      @top_left     = top_left
      @top_right    = top_right
      @bottom_right = bottom_right
      @bottom_left  = bottom_left
    end

    def determine_corners
      other_left  = Point.new @left.x, @right.y
      other_right = Point.new @right.x, @left.y
      if @left.y < other_left.y
        puts "dc #{@left}, #{other_right}, #{@right}, #{other_left}"
        self.corners = @left, other_right, @right, other_left
      else
        puts "dc #{other_left}, #{@right}, #{other_right}, #{@left}"
        corners = other_left, @right, other_right, @left
      end

      puts "top right #{@top_right}"
    end
  end
end