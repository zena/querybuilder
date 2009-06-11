=begin
"letters where foo > 5 from managers in site limit 5 group by section_id"
==>
[:group,
  [:limit,
    [:from,
      [:filter,
        [:relation,
          "letters"
        ],
        [:>,
          "foo",
          "5"
        ]
      ]
      [:relation,
        [:scope,
          "managers",
          "site"
        ]
      ]
    ],
    "5"
  ],
  "section_id"
]
=end
module NewQueryBuilder
  class QueryException < Exception
  end
  class Parser
    # http://dev.mysql.com/doc/refman/5.1/en/operator-precedence.html
    OP_PRECEDENCE = {
      "INTERVAL" => 40,
      "BINARY"   => 39, "COLLATE"  => 39,
      "!" => 38,
      "@-" => 37, "@~" => 37,
      "^" => 36,
      "*" => 35, "/" => 35, "DIV" => 35, "%" => 35, "MOD" => 35,
      "-" => 34, "+" => 34,
      "<<" => 33, ">>" => 33,
      "&" => 32,
      "|" => 31,
      "=" => 30, "<=>" => 30, ">=" => 30, ">" => 30, "<=" => 30, "<" => 30, "<>" => 30, "!=" => 30, "IS" => 30, "LIKE" => 30, "REGEXP" => 30, "IN" => 30,
      "BETWEEN" => 29, "CASE" => 29, "WHEN" => 29, "THEN" => 29, "ELSE" => 29,
      "NOT" => 28,
      "&&" => 27, "AND" => 27,
      "XOR" => 26,
      "||" => 25, "OR" => 25,
      ":=" => 24,
      "RELATION" => 13, "FILTER" => 13,
      "SCOPE" => 12,
      "FROM" => 11,
      "ASC"  => 10, "DESC" => 10,
      "CLAUSE" => 5,
      "CLAUSE_AND" => 4,
      "CLAUSE_OR" => 3,
      "OFFSET" => 2, "PAGINATE" => 2, "LIMIT" => 2, "ORDER" => 2, "GROUP" => 2,
      "QUERY" => 1,
      "PAR_CLOSE" => 0, "CLAUSE_PAR_CLOSE" => 0,
      "PAR" => -1, "CLAUSE_PAR" => -1
    }
    # group < from < filter < relation < scope

    # simple_state_machine.rl
    %%{
      machine pseudo_sql;
    
      action str_a {
        str_buf += fc.chr
      }
    
      action string {
        last << [:string, str_buf]
        str_buf = ""
      }
    
      action integer {
        last << [:integer, str_buf]
        str_buf = ""
      }
    
      action real {
        last << [:real, str_buf]
        str_buf = ""
      }
    
      action field {
        last << [:field, str_buf]
        str_buf = ""
      }
    
      action direction {
        last = apply_op(stack, str_buf.downcase.to_sym, false)
        str_buf = ""
      }
    
      action relation {
        if clause_state == :relation || clause_state == :parenthesis
          last = insert(stack, [:relation, str_buf])
          str_buf = ""
        end
      }
    
      action operator {
        last = apply_op(stack, str_buf.downcase.to_sym)
        str_buf = ""
      }
    
      action interval {
        last = apply_op(stack, :interval)
        last << str_buf
        str_buf = ""
      }
    
      action filter {
        last = apply_op(stack, :filter)
        clause_state = :filter
      }
    
      action goto_expr_p {
        # remember current machine state 'cs'
        last << [:par, cs]
        stack.push last.last
        last = last.last
        fgoto expr_p;
      }
    
      action expr_close {
        pop_stack(stack, :par_close)
        # reset machine state 'cs'
        cs = stack.last.delete_at(1)
        # one more time to remove [:par...] line
        stack.pop 
        last = stack.last
        # closing ')' must be parsed twice
        fhold;
      }
    
      action goto_clause_p {
        # remember current machine state 'cs'
        clause_state = :parenthesis
        last << [:clause_par, cs]
        stack.push last.last
        last = last.last
        fgoto clause_p;
      }
    
      action clause_close {
        pop_stack(stack, :clause_par_close)
        clause_state = :relation
        # reset machine state 'cs'
        cs = stack.last.delete_at(1)
        # one more time to remove [:clause_par...] line
        stack.pop 
        last = stack.last
        # closing ')' must be parsed twice
        fhold;
      }
    
      action scope {
        last = apply_op(stack, :scope)
        last << str_buf
        str_buf = ""
      }
    
      action offset {
        last = apply_op(stack, :offset)
      }
    
      action param {
        last << [:param, str_buf]
        str_buf = ""
      }
    
      action paginate {
        last = apply_op(stack, :paginate)
      }
    
      action limit {
        last = apply_op(stack, :limit)
        str_buf = ""
      }
    
      action order {
        last = apply_op(stack, :order)
        str_buf = ""
      }
    
      action group {
        last = apply_op(stack, :group)
      }
    
      action from_ {
        last = apply_op(stack, :from)
      }
    
      action join_clause {
        if clause_state == :relation
          last = apply_op(stack, "clause_#{str_buf}".to_sym)
          str_buf = ""
        end
      }
    
      action clause {
        last = insert(stack, [:clause])
      }
    
      action error {
        fhold;
        raise QueryException.new("Syntax error near #{data[p..-1].chomp.inspect}.")
      }
    
      action debug {
        print("_#{data[p..p]}")
      }
    
      ws       = ' ' | '\t' | '\n';
      var      = ws* ([a-zA-Z_]+) $str_a;
      dquote   = ([^"\\] | '\n') $str_a | ('\\' (any | '\n') $str_a);
      squote   = ([^'\\] | '\n') $str_a | ('\\' (any | '\n') $str_a);
      string   = ws* ("'" squote* "'" | '"' dquote* '"') %string;
      real     = ws* ('-'? ('0'..'9' digit* '.' digit+) ) $str_a %real;
      integer  = ws* ('-'? digit+ ) $str_a %integer;
      number   = (real | integer);
      op       = ws* ('+' | '-' | '<' | '<=' | '=' | '>=' | '>') $str_a;
      text_op  = ws+ ('or' $str_a | 'and' $str_a | ('not' $str_a %operator ws+)? 'like' $str_a ) ws+;
      operator = (op | text_op) %operator;
      interval = ws+ ('second'|'minute'|'hour'|'day'|'week'|'month'|'year') $str_a 's'? %interval;
      value    = ((var %field | string | number) interval? | ws* '(' >goto_expr_p ws* ')');
      expr     = value (operator value)*;
      expr_p  := expr ws* ')' $expr_close;
    
      relation = ws* var %relation;
      filter   = expr;
      filters  = ws+ 'where' %filter ws filter;
      scope    = ws+ 'in' ws var %scope;
    
      offset   = ws+ 'offset' %offset integer;
      paginate = ws+ 'paginate' %paginate var %param;
      limit    = ws+ 'limit' %limit integer (ws* ',' integer)?;
      direction= ws+ ('asc' | 'desc' | 'ASC' | 'DESC') $str_a %direction;
      order    = ws+ 'order' ws+ 'by' %order var %field (direction)? (ws* ',' var %field (direction)?)*;
      group    = ws+ 'group' ws+ 'by' %group var %field (ws* ',' var %field)*;
    
      part     = (relation filters? scope? | ws* '(' >goto_clause_p ws* ')');
      clause   = (part (ws+ 'from' %from_ part)* | '(' >goto_clause_p ws* ')' );
      clause_p:= clause ws* ')' $clause_close;
      main    := clause (ws+ ('or' | 'and') $str_a %join_clause ws clause)* limit? offset? paginate? order? group? '\n' $err(error);
    }%%

    %% write data;

    def self.parse(string)
      if string.kind_of?(Array)
        data = "(#{string.join(') or (')})"
      else
        data = "#{string}\n"
      end
      stack = [[:query]]
      last  = stack.last
      str_buf         = ""
      clause_state = :relation
      eof = 0;
      %% write init;
      %% write exec;
      
      raise QueryException.new("Syntax error near #{data[p..-1].chomp.inspect}.") if p != pe
      stack.first
    end
  
    def self.apply_op(stack, op, change_last = true)
      pop_stack(stack, op)
      last = stack.last
      change_elem = last.last
      last[-1] = [op.to_sym, change_elem]
      if change_last
        stack.push last[-1]
      end
      stack.last
    end
  
    def self.insert(stack, arg)
      # insert [:relation, "..."]
      # stack: [[:query]]  --> [[:query, [:relation, "..."]], [:relation, "..."]]
      pop_stack(stack, arg.first)
      last = stack.last
      last << arg
      stack.push last.last
      stack.last
    end
  
    def self.pop_stack(stack, op)
      # debug_stack(stack, op)
      stack_op = stack.last.first
      while OP_PRECEDENCE[op.to_s.upcase] <= OP_PRECEDENCE[stack_op.to_s.upcase]
        stack.pop
        stack_op = stack.last.first
      end
    end
  
    def self.debug_stack(stack, msg = '')
      puts "======= #{msg} ======="
      stack.reverse_each do |s|
        puts s.inspect
      end
      puts "======================"
    end
  end
end
