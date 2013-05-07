require 'rubyless'

module QueryBuilder
  class Processor
    attr_reader :context, :query, :sxp, :ancestor

    class << self
      # class variable
      attr_accessor :main_table, :main_class, :custom_queries, :custom_query_files
      attr_accessor :defaults
      attr_accessor :before_process_callbacks, :after_process_callbacks

      def set_main_table(table_name)
        self.main_table = table_name
      end

      def set_main_class(klass)
        self.main_class = klass
      end

      def set_default(key, value)
        self.defaults ||= {}
        self.defaults[key] = value
      end

      def before_process(callback)
        (self.before_process_callbacks ||= []) << callback
      end

      def after_process(callback)
        (self.after_process_callbacks ||= []) << callback
      end

      def insert_bind(str)
        if str.kind_of?(::RubyLess::TypedString)
          ::RubyLess::TypedString.new("[[#{str}]]", str.opts)
        else
          "[[#{str}]]"
        end
      end

      # Load prepared SQL definitions from a set of directories. If the file does not contain "group" or "groups" keys,
      # the filename is used as group.
      #
      # ==== Parameters
      # query<String>:: Path to list of custom queries yaml files.
      #
      # ==== Examples
      #   DummyQuery.load_custom_queries("/path/to/some/*/directory")
      #
      # The format of a custom query definition is:
      #
      #   groups:
      #     - test.host
      #   DummyQuery:      # QueryBuilder class
      #     abc:           # query's relation name
      #       select:      # selected fields
      #         - 'a'
      #         - '34 AS number'
      #         - 'c'
      #       tables:      # tables used
      #         - 'test'
      #       join_tables: # joins
      #         test:
      #           - LEFT JOIN other ON other.test_id = test.id
      #       where:    # filters
      #         - '1'
      #         - '2'
      #         - '3'
      #       order:  'a DESC' # order clause
      #
      # Once loaded, this 'custom query' can be used in a query like:
      #   "images from abc where a > 54"
      def load_custom_queries(directories)
        # lazy loading (evaluation happens on first query)
        self.custom_query_files ||= []
        self.custom_query_files << directories
      end

      def load_custom_queries!
        return unless list = self.custom_query_files
        klass = nil
        self.custom_queries ||= {'all' => {}}
        Dir.glob(list.flatten).each do |dir|
          if File.directory?(dir)
            Dir.foreach(dir) do |file|
              next unless file =~ /(.+).yml$/
              custom_query_groups = $1
              definitions = YAML::load(File.read(File.join(dir,file)))
              custom_query_groups = [definitions.delete('groups') || definitions.delete('group') || custom_query_groups].flatten
              definitions.each do |klass, query_list|
                begin
                  klass = QueryBuilder.resolve_const(klass)
                  klass = klass.query_compiler if klass.respond_to?(:query_compiler)
                  raise ArgumentError.new("Invalid Processor class '#{klass}' in '#{file}' custom query. Should be a descendant of QueryBuilder::Processor or respond to query_compiler.") unless klass.ancestors.include?(Processor)
                rescue NameError
                  raise ArgumentError.new("Unknown Processor class '#{klass}' in '#{file}' custom query.")
                end
                custom_queries = klass.custom_queries
                custom_query_groups.each do |custom_query_group|
                  custom_queries[custom_query_group] ||= {}
                  klass_queries = custom_queries[custom_query_group]
                  query_list.each do |query_name, query|
                    klass_queries[query_name] = query
                  end
                end
              end
            end
          end
        end
        self.custom_query_files = nil
      end
    end # class << self

    OPERATOR_TO_METHOD = {
      :"!" => :not,
      :"@-" => :change_sign, :"@~" => :invert_bits,
      :"^" => :bitwise_xor,
      :* => :times, :/ => :division, :DIV => :integer_division, :% => :modulo, :mod => :modulo,
      :- => :minus, :+ => :addition,
      :<< => :left_shift, :>> => :right_shift,
      :& => :bitwise_and,
      :| => :bitwise_or,
      :eq => :equal, :ge => :greater_or_equal,
      :gt => :greater, :le => :less_or_equal, :lt => :less, :ne => :not_equal,
      :"=" => :equal, :"<=>" => :null_safe_equal, :>= => :greater_or_equal,
      :> => :greater, :<= => :less_or_equal, :< => :less, :"<>" => :not_equal, :"!=" => :not_equal,
      :"&&" => :and,
      :"||" => :or,
      :":=" => :assign
    }

    METHOD_TO_OPERATOR = {
      :greater => :>, :greater_or_equal => :>=,
      :equal   => :'=',
      :less_or_equal => :<=, :less => :<,
      :not_equal => :'<>'
    }

    def initialize(source, opts = {})
      @default = opts.delete(:default) || {}
      @opts = opts
      @rubyless_helper  = @opts[:rubyless_helper]

      if source.kind_of?(Processor)
        # experimental: class change
        @context  = source.context
        @query    = source.query
        @sxp      = source.sxp
        @ancestor = source # used during class change to return back to previous 'this'
      elsif source.kind_of?(String)
        @sxp = Parser.parse(source)

        @context = opts.merge(:first => true, :last => true)
        @query = Query.new(self.class)
        @query.main_class = @opts[:main_class] || resolve_main_class(self.class.main_class)
        before_process

        process_all

        after_process

        if limit = @opts[:limit]
          @query.limit = " LIMIT #{limit}"
        end
      else
        raise QueryBuilder::Error.new("Cannot use #{source.class} as source: expected a String or QueryBuilder::Processor")
      end
    rescue QueryBuilder::Error => err
      raise err
    rescue Exception => err
      raise QueryBuilder::Error.new("Exception raised while processing '#{source}' (#{err.message})")
    end

    protected
      def before_process
        (self.class.before_process_callbacks || []).each do |callback|
          send(callback)
        end
      end

      def process_all
        if @sxp == [:query]
          # empty query
          process([:query, [:relation, main_table]])
        else
          process(@sxp)
        end
      end

      def after_process
        (self.class.after_process_callbacks || []).each do |callback|
          send(callback)
        end
      end

      # Returns the currently running processor (can be different if the class changed).
      def this
        @this || self
      end

      def this=(processor)
        @this = processor
      end

      def default(key)
        @default[key] || self.class.defaults[key]
      end
      
      # The passed :default scope is only applied on last context.
      def default_scope(context)
        if context[:last]
          default(:scope)
        else
          self.class.defaults[:scope]
        end
      end

      def process(sxp)
        return sxp if sxp.kind_of?(String)
        op = OPERATOR_TO_METHOD[sxp.first] || sxp.first
        method = "process_#{op}"
        if this.respond_to?(method)
          this.send(method, *sxp[1..-1])
        elsif sxp.size == 3
          op = METHOD_TO_OPERATOR[op] || sxp.first
          this.process_op(*([op] + sxp[1..-1]))
        else
          raise QueryBuilder::SyntaxError.new("Method '#{method}' to handle #{sxp.first.inspect} not implemented.")
        end
      end

      def process_clause_or(clause1, clause2)
        clauses = [clause2]

        while true
          if clause1.first == :clause_or
            clauses << clause1[2]
            clause1 = clause1[1]
          else
            clauses << clause1
            break
          end
        end

        clauses.map! do |clause|
          query = @query.dup
          with_query(query) do
            process(clause)
          end
          query
        end

        @query = merge_queries(clauses.reverse)
      end

      def merge_queries(queries, merge_filters = true)
        tables = []
        table_alias = {}

        queries.each do |query|
          tables += query.tables
          table_alias.merge!(query.table_alias)
        end

        tables.uniq!

        queries.each do |query|
          missing_tables = tables - query.tables
          missing_tables.each do |missing_table|
            if missing_table =~ /^(.+) AS (.+)$/
              resolve_missing_table(query, $1, $2)
            else
              resolve_missing_table(query, missing_table, missing_table)
            end
          end
        end

        query = queries.first
        query.tables = tables
        query.table_alias = table_alias

        query.where = [merge_or_filters(queries)] if merge_filters

        query.distinct = true

        # FIXME: !! We need to resolve main_class from different 'or' clauses !!
        # query.main_class = ...

        query
      end

      # Fix every query to work with the final list of tables (insert dummy clauses for example).
      def resolve_missing_table(query, table_alias, table_name)
        # raise an error
        raise QueryBuilder::Error.new("Could not resolve missing '#{table_name}' in OR clause.")
      end

      def merge_or_filters(queries)
        filters = queries.map do |query|
          query.where.size > 1 ? "(#{query.filter})" : query.where.first
        end

        "(#{filters.join(' OR ')})"
      end

      def process_clause_par(content)
        process(content)
      end

      # A query can be made of many clauses:
      # [letters from friends] or [images in project]
      def process_query(args)
        this.process(args)
        if @query.order.nil? && order = this.default(:order)
          sxp = Parser.parse("foo order by #{order}")
          order = sxp[1]
          order[1] = [:void] # replace [:relation, "foo"] by [:void]
          this.process(order)
        end
      end

      # Parse sub-query from right to left
      def process_from(query, sub_query)
        distinct!
        this.with(:first => false) do
          this.process(sub_query)
        end
        this.with(:last  => false) do
          this.process(query)
        end
      end

      # Returns true if the query is the one producing the final result.
      def first?
        this.context[:first]
      end

      # Returns true if the query is the closest to Ruby objects.
      def last?
        this.context[:last]
      end
=begin
    (3)          (2)                     (1)
    letters from friends in project from foo

    [:from,
      [:from,
        [:relation, "letters"],      (3)
        [:scope,
          [:relation, "friends"],    (2)
          "project"
        ]
      ],
      [:relation, "foo"]             (1)
    ]

    1. relation "foo"
         scope: nil ---> nothing to do
         where:    obj1.id = lk1.src_id AND lk1.rel_id = FOO AND lk1.trg_id = [[@node.id]]
    2. relation "friends"
         scope: "project"
           where:  obj2.project_id = obj1.project_id
         where:    obj3.id = lk2.src_id AND lk2.rel_id = FRIENDS AND lk2.trg_id = obj2.id
    3. relation "letters"
         scope: nil ---> parent
           where:  objects.parent_id = obj3.id
         where: objects.kpath like 'NNL%'

    In case (1) or (2), scope should be processed before the relation. In case (3),
    it should be processed after.
=end
      def process_relation(relation)
        if custom_query(relation)
          # load custom query
        elsif class_relation(relation)
          # changed class
        elsif (context[:scope_type] = :join)    && join_relation(relation)
        elsif (context[:scope_type] = :context) && context_relation(relation)
        elsif (context[:scope_type] = :filter)  && filter_relation(relation)
        else
          # Strange Ruby bug ? Using dstring directly in new method generates garbled UTF8...
          msg = "Unknown relation '#{relation}'."
          raise QueryBuilder::SyntaxError.new(msg)
        end
      end

      # See if the relation name means that we need to change processor class.
      def class_relation(relation)
        nil
      end

      # Try to use the relation name as a join relation (relation involving another table).
      def join_relation(relation)
        nil
      end

      # Try to use the relation name as a contextual relation (context filtering like "parent", "project", etc).
      def context_relation(relation)
        nil
      end

      # Try to use the relation name as a filtering relation and use default scope for scoping (ex: "images", "notes").
      def filter_relation(relation)
        nil
      end

      def process_scope(relation, scope)
        this.with(:scope => scope) do
          this.process(relation)
        end
      end

      def apply_scope(scope)
        context[:processing] = :scope
        if fields = scope_fields(scope)
          add_filter("#{field_or_attr(fields[0])} = #{field_or_attr(fields[1], table(main_table, -1))}") if fields != []
        else
          raise QueryBuilder::SyntaxError.new("Invalid scope '#{scope}'.")
        end
        true
      end

      def field_or_attr(fld_name, table_alias = table)
        if table_alias
          this.with(:table_alias => table_alias) do
            this.process_field(fld_name)
          end
        else
          this.process_attr(fld_name)
        end
      end

      def process_field(fld_name)
        if fld = @query.attributes_alias[fld_name]
          # use custom query alias value defined in select clause: 'custom_a AS validation'
          if processing_filter?
            "(#{fld})"
          elsif processing_having?
            @query.quote_column_name(fld_name)
          else
            fld
          end
        else
          raise QueryBuilder::SyntaxError.new("Unknown field '#{fld_name}'.")
        end
      end

      def process_integer(value)
        value
      end

      # Used by SQL functions
      def process_method(fld_name)
        fld_name
      end

      def process_attr(fld_name)
        if @rubyless_helper
          insert_bind(RubyLess.translate(@rubyless_helper, fld_name))
        else
          insert_bind(fld_name)
        end
      end

      def process_filter(relation, filter)
        process(relation)
        context[:processing] = :filter
        add_filter process(filter)
      end

      def process_select(*args)
        process(args.shift)
        context[:processing] = :select
        args.each do |arg|
          process(arg)
        end
      end

      def process_select_one(fld, name)
        test_fld = nil
        begin
          test_fld = process_field(name)
        rescue QueryBuilder::SyntaxError
        end

        if test_fld
          # ERROR
          raise QueryBuilder::SyntaxError.new("Cannot select #{name.inspect} (invalid name).")
        end
        add_select(process(fld), name)
      end

      def process_par(content)
        content.first == :or ? process(content) : "(#{process(content)})"
      end

      def process_string(string)
        quote(string)
      end

      def process_dstring(string)
        raise QueryBuilder::SyntaxError.new("Cannot parse rubyless (missing binding context).") unless helper = @rubyless_helper
        res = RubyLess.translate_string(helper, string)
        res.literal ? quote(res.literal) : insert_bind(res)
      end

      def process_rubyless(string)
        # compile RubyLess...
        raise QueryBuilder::SyntaxError.new("Cannot parse rubyless (missing binding context).") unless helper = @rubyless_helper
        res = RubyLess.translate(helper, string)
        res.literal ? quote(res.literal) : insert_bind(res)
      end

      def process_interval(value, interval)
        "INTERVAL #{this.process(value)} #{interval.upcase}"
      end

      def process_or(left, right)
        left_query  = @query.dup
        left_query.where = []
        right_query = @query.dup
        right_query.where = []

        with_query(left_query) do
          add_filter process(left)
        end

        with_query(right_query) do
          add_filter process(right)
        end

        merge_queries([left_query, right_query], false)
        @query.tables      = left_query.tables
        @query.table_alias = left_query.table_alias
        @query.distinct    = left_query.distinct

        merge_or_filters([left_query, right_query])
      end

      def with_query(query)
        bak = @query
        @query = query
        yield
        @query = bak
      end

      def process_op(op, left, right)
        "#{process(left)} #{op.to_s.upcase} #{process(right)}"
      end

      def process_raw(expr)
        expr.upcase
      end

      def process_in(*args)
        field  = process args.shift
        values = args.map {|val| process(val)}
        "#{field} IN (#{values.join(',')})"
      end

      def process_not(expr)
        if expr.first == :like
          "#{this.process(expr[1])} NOT LIKE #{this.process(expr[2])}"
        elsif expr.first == :in
          args = expr[1..-1]
          field  = process args.shift
          values = args.map {|val| process(val)}
          "#{field} NOT IN (#{values.join(',')})"
        else
          "NOT #{this.process(expr)}"
        end
      end

      def process_order(*args)
        variables = args
        process(variables.shift)  # parse query
        context[:processing] = :order
        @query.order = " ORDER BY #{variables.map {|var| process(var)}.join(', ')}"
      end

      def process_group(*args)
        variables = args
        process(variables.shift)  # parse query
        context[:processing] = :group
        @query.group = " GROUP BY #{variables.map {|var| process(var)}.join(', ')}"
      end

      def process_having(query, clause)
        process(query)
        context[:processing] = :having
        @query.having = " HAVING #{process(clause)}"
      end

      def process_void(*args)
        # do nothing
      end

      def process_limit(*args)
        variables = args
        process(variables.shift)  # parse query
        context[:processing] = :limit
        if variables.size == 1
          @query.limit  = " LIMIT #{process(variables.first)}"
        else
          @query.limit  = " LIMIT #{process(variables.last)}"
          @query.offset = " OFFSET #{process(variables.first)}"
        end
      end

      def process_offset(query, offset)
        process(query)
        raise QueryBuilder::SyntaxError.new("Invalid offset (used without limit).") unless @query.limit
        off = process(offset)
        if off.kind_of?(RubyLess::TypedString)
          # Make sure we get a number
          raise QueryBuilder::SyntaxError.new("Invalid offset (value is not a number)") unless off.klass <= Number
          raise QueryBuilder::SyntaxError.new("Invalid offset (value could be nil)") if off.could_be_nil?
        end
        context[:processing] = :limit
        @query.offset = " OFFSET #{process(offset)}"
      end

      def process_paginate(query, paginate_fld)
        process(query)
        raise QueryBuilder::SyntaxError.new("Invalid paginate clause (used without limit).") unless @query.limit
        context[:processing] = :paginate
        fld = process(paginate_fld)
        if fld && (page_size = @query.limit[/ LIMIT (\d+)/,1])
          @query.page_size = [1, page_size.to_i].max
          @query.offset = " OFFSET #{insert_bind("((#{fld}.to_i > 0 ? #{fld}.to_i : 1)-1)*#{@query.page_size}")}"
          @query.pagination_key ||= paginate_fld.last
        else
          raise QueryBuilder::SyntaxError.new("Limit value must be a fixed number to use pagination.")
        end
      end

      def process_equal(left, right)
        process_op(:"=", left, right)
      end

      # Used by paginate
      def process_param(param)
        param
      end

      def process_asc(field)
        "#{process(field)} ASC"
      end

      def process_desc(field)
        "#{process(field)} DESC"
      end

      def process_function(arg, method)
        raise QueryBuilder::SyntaxError.new("SQL function '#{process(method)}' not allowed.")
      end

      # ******** And maybe overwrite these **********
      def parse_custom_query_argument(key, value)
        return nil unless value
        case key
        when :order
          " ORDER BY #{value}"
        when :group
          " GROUP BY #{value}"
        else
          value
        end
      end

      def resolve_main_class(class_name)
        QueryBuilder.resolve_const(class_name)
      end

      def insert_bind(str)
        self.class.insert_bind(str)
      end

      def with(hash)
        context_bak = @context
        res = ''
        @context = @context.merge(hash)
        res = yield
        @context = context_bak
        res
      end

      def restoring_this
        processor = self.this
        yield
        if processor != self.this
          # changed class, we need to change back
          change_processor(processor)
        end
      end

      def change_processor(processor, opts = {})
        if @this
          @this.change_processor(processor)
        else
          if processor.kind_of?(String)
            processor = QueryBuilder.resolve_const(processor)
          end

          if processor.kind_of?(Processor)
            # instance of processor
          elsif processor <= Processor
            processor = processor.new(this, opts)
          else
            raise QueryBuilder::SyntaxError.new("Cannot use #{processor} as Query compiler (not a QueryBuilder::Processor).")
          end

          @query.processor_class = processor.class
          @query.main_class = processor.resolve_main_class(processor.class.main_class)
          update_processor(processor)
        end
      end

      def update_processor(processor)
        @this = processor
        if @ancestor
          @ancestor.update_processor(processor)
        end
      end

      def custom_query_without_loading(relation)
        return false unless first? && last?  # current safety net until "from" is correctly implemented and tested

        if custom_queries = self.class.custom_queries
          queries = custom_queries[@opts[:custom_query_group]] || {}
          rel     = relation.singularize
          if custom_query = queries[rel] || custom_queries['all'][rel]
            custom_query.each do |k,v|
              @query.send(:instance_variable_set, "@#{k}", prepare_custom_query_arguments(k.to_sym, v))
            end
            # rebuild table alias
            @query.rebuild_tables!
            # rebuild 'select' aliases
            @query.rebuild_attributes_hash!
            true
          end
        end
      end

      # Method executed only once, then alias resolves to custom_query_without_loading.
      def custom_query(*args)
        self.class.load_custom_queries!
        self.class.class_eval do
          alias custom_query custom_query_without_loading
        end
        custom_query_without_loading(*args)
      end

    private

      %W{filter select scope limit offset paginate group having order}.each do |context|
        # Return true if we are expanding a filter / scope / limit / etc
        class_eval(%Q{
          def processing_#{context}?
            context[:processing] == :#{context}
          end
        }, __FILE__, __LINE__ - 2)
      end

      # Parse custom query arguments for special keywords (RELATION, NODE_ATTR, ETC)
      # There might be a better way to use custom queries that avoids this parsing
      def prepare_custom_query_arguments(key, value)
        if key == :main_class
          resolve_main_class(value)
        elsif key == :types
          value.each do |k,v|
            value[k] = v.to_sym
          end
        elsif value.kind_of?(Array)
          value.map {|e| parse_custom_query_argument(key, e)}
        elsif value.kind_of?(Hash)
          value.each do |k,v|
            if v.kind_of?(Array)
              value[k] = v.map {|e| parse_custom_query_argument(key, e)}
            else
              value[k] = parse_custom_query_argument(key, v)
            end
          end
        else
          parse_custom_query_argument(key, value)
        end
      end

      def table(table_name = nil, index = 0)
        if table_name.nil?
          # Current context's table_alias
          context[:table_alias] ||
          # Search in the used tables:
          @query.table(@query.main_table, index) ||
          # Tables have not been introduced (custom_query):
          @query.main_table
        else
          @query.table(table_name, index)
        end
      end

      # Add a new table and apply scoping when needed
      def add_table(use_name, table_name = nil, type = nil, &block)
        if use_name == main_table && first?
          # we are now using final table
          context[:table_alias] = use_name
          avoid_alias = true
        else
          avoid_alias = false
        end

        if use_name == main_table
          if context[:scope_type] == :join
            context[:scope_type] = nil
            # pre scope
            if context[:scope] && need_join_scope?(context[:scope])
              @query.add_table(main_table, main_table, avoid_alias)
              apply_scope(context[:scope])
            end
            
            @query.add_table(use_name, table_name, avoid_alias, type, &block)
          elsif context[:scope_type] == :filter
            context[:scope_type] = nil
            # post scope
            tbl = @query.add_table(use_name, table_name, avoid_alias, &block)
            apply_scope(context[:scope] || default_scope(context))
            tbl
          else
            # scope already applied / skip
            @query.add_table(use_name, table_name, avoid_alias, type, &block)
          end
        else
          # no scope
          # can only scope main_table
          @query.add_table(use_name, table_name, true, type, &block)
        end
      end

      # Add a table to 'import' a key/value based field. This method ensures that
      # a given field is only included once for each context.
      def add_key_value_table(use_name, index_table, key = :any, &block)
        @query.add_key_value_table(use_name, index_table, key, &block)
      end

      # Hook to use dummy scopes (such as 'in site')
      def need_join_scope?(scope_name)
        true
      end

      def main_table
        @query.main_table
      end

      def set_main_class(klass)
        # FIXME: be clever on different klass settings in filters (AND / OR)...
        @query.main_class = klass
      end

      def needs_join_table(*args)
        @query.needs_join_table(*args)
      end

      def add_filter(*args)
        @query.add_filter(*args)
      end

      def add_select(*args)
        @query.add_select(*args)
      end

      def quote(arg)
        # we must backslash twice because 'eval' will take one out:
        # 'l\\'avion' ==> 'l\'avion' ==> ok
        connection.quote(arg).gsub('\\','\\\\\\\\') # we need 8
      end

      def connection
        @connection ||= @query.default_class.connection
      end

      def distinct!
        @query.distinct = true
      end
  end
end