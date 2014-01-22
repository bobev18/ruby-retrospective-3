class Asm

  class Processor
    attr_reader :ax, :bx, :cx, :dx

    def initialize
      @ax, @bx, @cx, @dx = 0, 0, 0, 0
      @comparison_result = 0
    end

    def equality(destination, source)
      case source
        when :ax then val = @ax
        when :bx then val = @bx
        when :cx then val = @cx
        when :dx then val = @dx
      else
        val = source
      end

      case destination
        when :ax then @ax = val
        when :bx then @bx = val
        when :cx then @cx = val
        when :dx then @dx = val
      end
    end

    def increment(destination, value)
      case value
        when :ax then val = @ax
        when :bx then val = @bx
        when :cx then val = @cx
        when :dx then val = @dx
      else
        val = value
      end

      case destination
        when :ax then @ax += val
        when :bx then @bx += val
        when :cx then @cx += val
        when :dx then @dx += val
      end
    end

    def decrement(destination, value)
      case value
        when :ax then val = @ax
        when :bx then val = @bx
        when :cx then val = @cx
        when :dx then val = @dx
      else
        val = value
      end

      case destination
        when :ax then @ax -= val
        when :bx then @bx -= val
        when :cx then @cx -= val
        when :dx then @dx -= val
      end
    end

    def compare(register, value)
      case value
        when :ax then val = @ax
        when :bx then val = @bx
        when :cx then val = @cx
        when :dx then val = @dx
      else
        val = value
      end

      case register
        when :ax then @comparison_result = @ax - val
        when :bx then @comparison_result = @bx - val
        when :cx then @comparison_result = @cx - val
        when :dx then @comparison_result = @dx - val
      end
    end

    def jump(position)
      if position.is_a? Symbol
        @pointer = public_send(position)
      else
        @pointer = position
      end
    end

  def jump_equal(position)
    if @comparison_result == 0
      jump(position)
    end
  end

  def jump_not_equal(position)
    if @comparison_result != 0
      jump(position)
    end
  end

  def jump_less(position)
    if @comparison_result < 0
      jump(position)
    end
  end

  def jump_less_equal(position)
    if @comparison_result <= 0
      jump(position)
    end
  end

  def jump_greater(position)
    if @comparison_result > 0
      jump(position)
    end
  end

  def jump_greater_equal(position)
    if @comparison_result >= 0
      jump(position)
    end
  end








  end

  def initialize
    # @ax, @bx, @cx, @dx = 0, 0, 0, 0
    @operations = {}
    @line_number = 0
    # @comparison_result = 0
    @processor = Processor.new
  end

  def label(name)
    local_number = @line_number
    # I tried using define method directly but it was failing -- not sure why
    self.class.send(:define_method, name) do
      local_number
    end
  end

  two_argument_operations = {
    mov: :equality,
    cmp: :compare,
  }
  # two_argument_operations.each do |operation_name, operation|
  #   define_method operation_name do |destination, source|
  #     @operations[@line_number] = [operation, destination, source]
  #     @line_number += 1
  #     puts "i was here"
  #   end
  # end

  default_argument_operations = {
    inc: :increment,
    dec: :decrement
  }

  def mov(destination, source)
    @operations[@line_number] = [:equality, destination, source]
    @line_number += 1
  end

  def inc(destination, value = 1)
    @operations[@line_number] = [:increment, destination, value]
    @line_number += 1
  end

  def dec(destination, value = 1)
    @operations[@line_number] = [:decrement, destination, value]
    @line_number += 1
  end

  def jmp(position)
    @operations[@line_number] = [:jump, position]
    @line_number += 1
  end

  def cmp(register, value)
    @operations[@line_number] = [:compare, register, value]
    @line_number += 1
  end

  def je(position)
    @operations[@line_number] = [:jump_equal, position]
    @line_number += 1
  end

  def jne(position)
    @operations[@line_number] = [:jump_not_equal, position]
    @line_number += 1
  end

  def jl(position)
    @operations[@line_number] = [:jump_less, position]
    @line_number += 1
  end

  def jle(position)
    @operations[@line_number] = [:jump_less_equal, position]
    @line_number += 1
  end

  def jg(position)
    @operations[@line_number] = [:jump_greater, position]
    @line_number += 1
  end

  def jge(position)
    @operations[@line_number] = [:jump_greater_equal, position]
    @line_number += 1
  end

  def execute
    @operations[@line_number] = :end
    @pointer = 0
    while @operations[@pointer] != :end do # |picked_number|
      old_pointer = @pointer
      result = @processor.public_send(*@operations[@pointer])
      if @operations[@pointer] != :end and old_pointer == @pointer
        @pointer +=1
      end
    end
    [@ax, @bx, @cx, @dx]
    [@processor.ax, @processor.bx, @processor.cx, @processor.dx]
  end

  def self.asm(&block)
    asm = new
    asm.instance_eval &block
    asm.execute
  end

  def method_missing(name, *args)
    name.to_sym
  end
end