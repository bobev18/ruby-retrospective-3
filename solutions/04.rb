class Asm
  def self.asm(&block)
    asm = Operations.new
    asm.instance_eval &block
    asm.execute
  end


  class Operations
    attr_reader :operations

    def initialize
      # @ax, @bx, @cx, @dx = 0, 0, 0, 0
      @operations = {}
      @labels = []
      @line_number = 0
      # @comparison = 0
      @processor = Processor.new
    end

    def method_missing(name, *args)
      name.to_sym
    end

    def label(name)
      local_number = @line_number
      @labels << name
      # I tried using define method directly but it was failing -- not sure why
      # define_method(name) do
      self.class.send(:define_method, name) do
        local_number
      end
    end

    def clean_up
      @labels.each do |label_name|
        # remove_method label_name
        self.class.send(:remove_method, label_name)
      end
    end

    two_argument_operations = {
      mov: :assignment,
      cmp: :compare,
    }
    two_argument_operations.each do |operation_name, operation|
      define_method operation_name do |destination, source|
        @operations[@line_number] = [operation, destination, source]
        @line_number += 1
      end
    end

    default_argument_operations = {
      inc: :increment,
      dec: :decrement
    }
    default_argument_operations.each do |operation_name, operation|
      define_method operation_name do |destination, value = 1|
        @operations[@line_number] = [operation, destination, value]
        @line_number += 1
      end
    end

    one_argument_operations = {
      jmp: :jump,
      je:  :jump_equal,
      jne: :jump_not_equal,
      jl:  :jump_less,
      jle: :jump_less_equal,
      jg:  :jump_greater,
      jge: :jump_greater_equal
    }
    one_argument_operations.each do |operation_name, operation|
      define_method operation_name do |position|
        @operations[@line_number] = [operation, position]
        @line_number += 1
      end
    end

    def execute
      @operations[@line_number] = :end
      @pointer = 0
      while @operations[@pointer] != :end do # |picked_number|
        old_pointer = @pointer
        result = @processor.public_send(*@operations[@pointer])
        @pointer = result if result
        if @operations[@pointer] != :end and old_pointer == @pointer
          @pointer +=1
        end
      end
      clean_up
      # [@ax, @bx, @cx, @dx]
      [@processor.ax, @processor.bx, @processor.cx, @processor.dx]
    end
  end

  class Processor < Operations
    attr_reader :ax, :bx, :cx, :dx

    def initialize
      @ax, @bx, @cx, @dx = 0, 0, 0, 0
      @comparison = 0
    end

    def read(register_or_value)
      if [:ax, :bx, :cx, :dx].include? register_or_value
        public_send(register_or_value)
      else
        register_or_value
      end
    end

    def write(destination, value)
      case destination
        when :ax then @ax = value
        when :bx then @bx = value
        when :cx then @cx = value
        when :dx then @dx = value
      end
    end

    def assignment(destination, source)
      val = read(source)
      write(destination, val)
      nil
    end

    def increment(destination, value)
      val = read(value)
      old_val = read(destination)
      write(destination, old_val + val)
      nil
    end

    def decrement(destination, value)
      val = read(value)
      old_val = read(destination)
      write(destination, old_val - val)
      nil
    end

    def compare(register, value)
      val = read(value)
      base = read(register)
      write(@comparison, base - val)

      # case register
      #   when :ax then @comparison = @ax - val
      #   when :bx then @comparison = @bx - val
      #   when :cx then @comparison = @cx - val
      #   when :dx then @comparison = @dx - val
      # end
      nil
    end

    # def method_missing(name, *args)
    #   super
    # end

    def jump(position, operation = nil)
      return nil if operation and not @comparison.public_send(operation, 0)
      if position.is_a? Symbol
        # raise # this send should be against the other class,
        #   because there we have defined the labels
        public_send(position)
      else
        position
      end
    end

    def jump_not_equal(position)
      jump(position) if @comparison != 0
    end

    jumps = {
      jump_equal: :==,
      # jump_not_equal: :_=,
      jump_less: :<,
      jump_less_equal: :<=,
      jump_greater: :>,
      jump_greater_equal: :>=,
    }

    jumps.each do |operation_name, operation|
      define_method operation_name do |position|
        jump(position, operation)# if @comparison.public_send(operation, 0)
      end
    end

  end


end