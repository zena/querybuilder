%%{
  machine querybuilder;
  
  ws       = ' ' | '\t' | '\n';
  var      = ws* ([a-zA-Z_]+) $str_a;
  dquote   = ([^"\\] | '\n') $str_a | ('\\' (any | '\n') $str_a);
  squote   = ([^'\\] | '\n') $str_a | ('\\' (any | '\n') $str_a);
  string   = ws* ("'" squote* "'" >string | '"' dquote* '"' >string);
  real     = ws* ('-'? ('0'..'9' digit* '.' digit+) ) $str_a %real;
  integer  = ws* ('-'? digit+ ) $str_a %integer;
  number   = (real | integer);
  op       = ws* ('+' | '-' | '<' | '<=' | '=' | '>=' | '>') $str_a;
  text_op  = ws+ (('or' | 'and' | 'lt' | 'le' | 'eq' | 'ne' | 'ge' | 'gt') $str_a | ('not' $str_a %operator ws+)? 'like' $str_a);
  operator = (op %operator | text_op %operator ws+);
  interval = ws+ ('second'|'minute'|'hour'|'day'|'week'|'month'|'year') $str_a %interval 's'?;
  value    = ((var %field | string | number) interval? | ws* '(' >goto_expr_p ws* ')');
  expr     = value (operator value)*;
  expr_p  := expr ws* ')' $expr_close;

  relation = ws* var %relation;
  filter   = expr ;
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
  main    := clause (ws+ ('or' | 'and') $str_a %join_clause ws clause)* limit? offset? paginate? order? group? ('\n' | ws)+ $err(error);

}%%