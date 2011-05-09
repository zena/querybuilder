module QueryBuilder
  class Parser
    class << self
      # http://dev.mysql.com/doc/refman/5.1/en/operator-precedence.html
      OP_PRECEDENCE = {
        :function => 50, :select_one => 50,
        :interval => 40,
        :binary   => 39, :collate  => 39,
        :"!" => 38,
        :"@-" => 37, :"@~" => 37,
        :"^" => 36,
        :"*" => 35, :"/" => 35, :div => 35, :"%" => 35, :mod => 35,
        :"-" => 34, :"+" => 34,
        :"<<" => 33, :">>" => 33,
        :"&" => 32,
        :"|" => 31,
        :"=" => 30, :"<=>" => 30, :">=" => 30, :">" => 30, :"<=" => 30, :"<" => 30, :"<>" => 30, :"!=" => 30, :is => 30, :like => 30, :regexp => 30, :in => 30,
        :lt => 30, :le => 30, :eq => 30, :ne => 30, :ge => 30, :gt => 30, :match => 30,
        :between => 29, :case => 29, :when => 29, :then => 29, :else => 29,
        :not => 28,
        :"&&" => 27, :and => 27,
        :xor => 26,
        :"||" => 25, :or => 25,
        :":=" => 24,
        :relation => 13, :filter => 13, :select => 13,
        :scope => 12,
        :from => 11,  # this is not the same as SQL 'FROM', it's "icons from friends"
        :asc  => 10, :desc => 10,
        :clause => 5,
        :clause_and => 4,
        :clause_or => 3,
        :offset => 2, :paginate => 2, :limit => 2, :order => 2, :group => 2,
        :query => 1,
        :par_close => 0, :clause_par_close => 0,
        :par => -1, :clause_par => -1
      }
      # group < from < filter < relation < scope

      # Transform the stack to wrap the last element with an operator:
      # [a, b, c] ==> [a, b, [op, c, d]]
      def apply_op(stack, op, change_last = true)
        pop_stack(stack, op)
        last = stack.last
        change_elem = last.last
        last[-1] = [op.to_sym, change_elem]
        if change_last
          stack.push last[-1]
        end
        stack.last
      end

      def insert(stack, arg)
        # insert [:relation, "..."]
        # stack: [[:query]]  --> [[:query, [:relation, "..."]], [:relation, "..."]]
        pop_stack(stack, arg.first)
        last = stack.last
        last << arg
        stack.push last.last
        stack.last
      end

      def pop_stack(stack, op)
        #debug_stack(stack, op)
        stack_op = stack.last.first
        while OP_PRECEDENCE[op] <= OP_PRECEDENCE[stack_op]
          stack.pop
          stack_op = stack.last.first
        end
      end

      def debug_stack(stack, msg = '')
        puts "======= #{msg} ======="
        stack.reverse_each do |s|
          puts s.inspect
        end
        puts "======================"
      end
    end
  end
end
