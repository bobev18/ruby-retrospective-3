class Asm
  def self.asm(&block)
    asm = Operations.new
    asm.instance_eval &block
    puts "ops #{asm.operations.size}"
    asm.operations.each { |op| puts op.inspect }
    puts
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
      puts "*** method method_missing '#{name}', returning Symbol"
      name.to_sym
    end

    def label(name)
      local_number = @line_number
      @labels << name
      puts "lable to create method #{name}"
      # I tried using define method directly but it was failing -- not sure why
      # define_method(name) do
      self.class.send(:define_method, name) do
        puts "this is dynamically created method '#{name}',"
        puts "which returns #{local_number}"
        local_number
      end
    end

    def clean_up
      puts "cleaning..."
      @labels.each do |label_name|
        # remove_method label_name
        self.class.send(:remove_method, label_name)
        puts "call public_send(#{label_name}) should just return a Symbol:"
        puts "#{public_send(label_name)}"
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
        puts "2 arg created #{@operations[@line_number-1]}"
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
        puts "1 arg 1 default created #{@operations[@line_number-1]}"
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
        puts "1 arg created #{@operations[@line_number-1]}"
      end
    end

    def execute
      @operations[@line_number] = :end
      @pointer = 0
      while @operations[@pointer] != :end do # |picked_number|
        old_pointer = @pointer
        puts "processing operation #{@pointer}: #{@operations[@pointer]}"
        result = @processor.public_send(*@operations[@pointer])
        @pointer = result if result
        if @operations[@pointer] != :end and old_pointer == @pointer
          @pointer +=1
        end
      end
      clean_up
      puts "\n\n"
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

    def assignment(destination, source)
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
      nil
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
      nil
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
      nil
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
        when :ax then @comparison = @ax - val
        when :bx then @comparison = @bx - val
        when :cx then @comparison = @cx - val
        when :dx then @comparison = @dx - val
      end
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
        puts "I'm jumping to #{position}"
        jump(position, operation)# if @comparison.public_send(operation, 0)
      end
    end

  end


end