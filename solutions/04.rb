class Asm

  def initialize
    @ax, @bx, @cx, @dx = 0, 0, 0, 0
    @operations = {}
    @line_number = 0
    @comparison_result = 0
  end

  def label(name)
    local_number = @line_number
    self.class.send(:define_method, name) do
      local_number
    end
  end

  def mov(destination, source)
    @operations[@line_number] = [:equality, destination, source]
    @line_number += 1
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

  def inc(destination, value = 1)
    @operations[@line_number] = [:increment, destination, value]
    @line_number += 1
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

  def dec(destination, value = 1)
    @operations[@line_number] = [:decrement, destination, value]
    @line_number += 1
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

  def jmp(position)
    @operations[@line_number] = [:jump, position]
    @line_number += 1
  end

  def jump(position)
    if position.is_a? Symbol
      @pointer = public_send(position)
    else
      @pointer = position
    end
  end

  def cmp(register, value)
    @operations[@line_number] = [:compare, register, value]
    @line_number += 1
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

  def je(position)
    @operations[@line_number] = [:jump_equal, position]
    @line_number += 1
  end

  def jump_equal(position)
    if @comparison_result == 0
      jump(position)
    end
  end

  def jne(position)
    @operations[@line_number] = [:jump_not_equal, position]
    @line_number += 1
  end

  def jump_not_equal(position)
    if @comparison_result != 0
      jump(position)
    end
  end

  def jl(position)
    @operations[@line_number] = [:jump_less, position]
    @line_number += 1
  end

  def jump_less(position)
    if @comparison_result < 0
      jump(position)
    end
  end

  def jle(position)
    @operations[@line_number] = [:jump_less_equal, position]
    @line_number += 1
  end

  def jump_less_equal(position)
    if @comparison_result <= 0
      jump(position)
    end
  end

  def jg(position)
    @operations[@line_number] = [:jump_greater, position]
    @line_number += 1
  end

  def jump_greater(position)
    if @comparison_result > 0
      jump(position)
    end
  end

  def jge(position)
    @operations[@line_number] = [:jump_greater_equal, position]
    @line_number += 1
  end

  def jump_greater_equal(position)
    if @comparison_result >= 0
      jump(position)
    end
  end

  def execute
    @operations[@line_number] = :end
    @pointer = 0
    while @operations[@pointer] != :end do # |picked_number|
      old_pointer = @pointer
      result = public_send(*@operations[@pointer])
      if @operations[@pointer] != :end and old_pointer == @pointer
        @pointer +=1
      end
    end
    [@ax, @bx, @cx, @dx]
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