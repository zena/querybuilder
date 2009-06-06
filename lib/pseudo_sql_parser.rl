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
      [:scope,
        [:relation,
          "managers"
        ],
        "site"
      ]
    ],
    "5"
  ],
  "section_id"
]
=end
class PseudoSQLParser
  # http://dev.mysql.com/doc/refman/5.1/en/operator-precedence.html
  OP_PRECEDENCE = {
    "INTERVAL" => 20,
    "BINARY"   => 19, "COLLATE"  => 19,
    "!" => 18,
    "@-" => 17, "@~" => 17,
    "^" => 16,
    "*" => 15, "/" => 15, "DIV" => 15, "%" => 15, "MOD" => 15,
    "-" => 14, "+" => 14,
    "<<" => 13, ">>" => 13,
    "&" => 12,
    "|" => 11,
    "=" => 10, "<=>" => 10, ">=" => 10, ">" => 10, "<=" => 10, "<" => 10, "<>" => 10, "!=" => 10, "IS" => 10, "LIKE" => 10, "REGEXP" => 10, "IN" => 10,
    "BETWEEN" => 9, "CASE" => 9, "WHEN" => 9, "THEN" => 9, "ELSE" => 9,
    "NOT" => 8,
    "&&" => 7, "AND" => 7,
    "XOR" => 6,
    "||" => 5, "OR" => 5,
    ":=" => 4,
    "RELATION" => 3, "FILTER" => 3,
    "SCOPE" => 2, "FROM" => 2, "OFFSET" => 2, "PAGINATE" => 2, "LIMIT" => 2, "ORDER" => 2, "GROUP" => 2,
    "QUERY" => 0,
  }

  # simple_state_machine.rl
  %%{
    machine hello;
    
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
    
    action compare {
      last = apply_op(stack, str_buf.to_sym)
      str_buf = ""
    }
    
    action relation {
      last << [:relation, str_buf]
      str_buf = ""
    }
    
    action operator {
      last = apply_op(stack, str_buf.to_sym)
      str_buf = ""
    }
    
    action filter {
      last = apply_op(stack, :filter)
    }
    
    action scope {
      last = apply_op(stack, :scope)
      last << str_buf
      str_buf = ""
    }
    
    action offset {
      last = apply_op(stack, :offset)
    }
    
    action paginate {
      last = apply_op(stack, :paginate)
    }
    
    action limit {
      last = apply_op(stack, :limit)
    }
    
    action order {
      last = apply_op(stack, :order)
    }
    
    action group {
      last = apply_op(stack, :from)
    }
    
    action from_ {
      last = apply_op(stack, :from)
    }
    
    action error {
      fhold;
      puts "Syntax error near '#{data[p..-1]}'."
      return nil
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
    integer  = ws* ('-'? ('0'..'9' digit*) ) $str_a %integer;
    number   = (real | integer);
    operator = ws* ('+' | '-') $str_a %operator;
    value_e  = (var %field | string | number);
    value    = value_e (operator value_e)*;
    compare  = ws* ('<' | '<=' | '=' | '>=' | '>') $str_a %compare;
    relation = ws* var %relation;
    expr     = (value compare value);
    filter   = expr;
    filters  = ws+ 'where' %filter ws filter;
    scope    = ws+ 'in' ws var %scope;
    
    offset   = ws+ 'offset' %offset;
    paginate = ws+ 'paginate' %paginate;
    limit    = ws+ 'limit' %limit;
    order    = ws+ 'order' ws+ 'by' %order;
    group    = ws+ 'group' ws+ 'by' %group;
    
    part     = (relation filters? scope?);
    
    main    := part (ws+ 'from' %from_ part)* offset? paginate? limit? order? group? '\n' $err(error);
  }%%

  %% write data;

  def self.parse(string)
    data = "#{string}\n"
    stack = [[:query]]
    last  = stack.last
    str_buf    = ""
    eof = 0;
    %% write init;
    %% write exec;
    stack.first
  end
  
  def self.apply_op(stack, op)
    pop_stack(stack, op)
    last = stack.last
    change_elem = last.last
    last[-1] = [op.to_sym, change_elem]
    stack.push last[-1]
    last[-1]
  end
  
  def self.insert(stack, op, var)
    pop_stack(stack, op)
    stack.last << [op.to_sym, var]
    if var.kind_of?(Array)
      stack.push var
    end
    stack.last
  end
  
  def self.pop_stack(stack, op)
    stack_op = stack.last.first
    while OP_PRECEDENCE[op.to_s.upcase] < OP_PRECEDENCE[stack_op.to_s.upcase]
      stack.pop
      stack_op = stack.last.first
    end
  end
end