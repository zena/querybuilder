class DummyProcessor < QueryBuilder::Processor
  set_main_table 'objects'
  set_main_class 'DummyClass'
  set_default :scope, 'self'
  after_process :insert_after_filter
  load_custom_queries File.join(File.dirname(__FILE__), '*')

  # Scope current context with previous context.
  # For example:
  #                          current         previous
  #  ['parent_id', 'id'] ==> no1.parent_id = nodes.id
  def scope_fields(scope)
    case scope
    when 'self'
      ['parent_id', 'id']
    when 'parent'
      last? ? ['parent_id', 'parent_id'] : ['parent_id', 'id']
    when 'project'
      last? ? ['project_id', 'project_id'] : ['project_id', 'id']
    when 'site', main_table
      # not an error, but do not scope
      []
    else
      # error
      nil
    end
  end

  # Overwrite this and take care to check for valid fields.
  def process_field(field_name)
    if ['id', 'parent_id', 'project_id', 'section_id', 'kpath', 'name', 'event_at', 'custom_a', 'idx_foo1' , 'amount'].include?(field_name)
      "#{table}.#{field_name}"
    elsif field_name == 'REF_DATE'
      context[:ref_date] ? insert_bind(context[:ref_date]) : 'now()'
    elsif %w{age size}.include?(field_name)
      tbl = add_key_value_table('idx', 'idx_nodes', field_name) do |tbl_name|
        # This block is only executed once
        add_filter "#{tbl_name}.node_id = #{table}.id"
        add_filter "#{tbl_name}.key = #{quote(field_name)}"
      end

      "#{tbl}.value"
    else
      super # raises an error
    end
  end

  def resolve_missing_table(query, table_name, table_alias)
    case table_name
    when 'idx_nodes'
      query.where.insert 0, "#{table_alias}.id = 0"
    when 'links'
      query.where.insert 0, "#{table_alias}.id = 0"
    else
      # Raise an error
      super
    end
    # do nothing
  end

  # We do special things with 'class ='
  def process_equal(left, right)
    if left == [:field, 'class'] && right[0] == :string
      case right.last
      when 'Client'
        kpath = 'NRCC'
      else
        raise QueryBuilder::SyntaxError.new("Unknown class #{right.last.inspect}.")
      end
      "#{field_or_attr('kpath')} LIKE #{insert_bind((kpath + '%').inspect)}"
    else
      super
    end
  end

  # We do special things with 'class ='
  def process_match(left, right)
  end

  def process_function(arg, method, *args)
    method, arg = process(method), process(arg)

    case method
    when 'year'
      "strftime('%Y',#{arg})"
    when 'count'
      "COUNT(#{arg})"
    when 'sum'
      "SUM(#{arg})"
    when 'coalesce'
      args = [arg] + args.map{|a| process(a)}
      "COALESCE(#{args.join(',')})"
    when 'min'
      args = [arg] + args.map{|a| process(a)}
      "MIN(#{args.join(',')})"
    else
      super
    end
  end

  # ******** And maybe overwrite these **********
  def parse_custom_query_argument(key, value)
    return nil unless value
    super(key, value.gsub('REF_DATE', context[:ref_date] ? insert_bind(context[:ref_date]) : 'now()'))
  end

  private
    # Change class
    def class_relation(relation)
      case relation
      when 'users'
        change_processor 'UserProcessor'
        add_table('users')
        add_filter "#{table('users')}.node_id = #{field_or_attr('id', table(self.class.main_table))}"
        return true
      else
        return nil
      end
    end

    # Moving to another context without a join table
    def context_relation(relation)
      case relation
      when 'self'
        fields = ['id', 'id']
      when 'parent'
        fields = ['id', 'parent_id']
      when 'project'
        fields = ['id', 'project_id']
      else
        return nil
      end

      add_table(main_table)
      add_filter "#{field_or_attr(fields[0])} = #{field_or_attr(fields[1], table(main_table, -1))}"
    end

    # Filtering of objects in scope
    def filter_relation(relation)
      case relation
      when 'letters'
        add_table(main_table)
        add_filter "#{table}.kpath LIKE #{quote('NNL%')}"
      when 'clients'
        add_table(main_table)
        add_filter "#{table}.kpath LIKE #{quote("NRCC%")}"
      when main_table, 'children'
        # no filter
        add_table(main_table)
      end
    end

    # Moving to another context through 'joins'
    def join_relation(relation)
      case relation
      when 'recipients'
        fields = ['source_id', 4, 'target_id']
      when 'icons'
        fields = ['target_id', 5, 'source_id']
      when 'tags'
        # just to test joins
        add_table(main_table)
        needs_join_table('objects', 'INNER', 'tags', 'TABLE1.id = TABLE2.node_id')
        return true
      else
        return false
      end

      add_table(main_table)
      add_table('links')
      # source --> target
      add_filter "#{table('links')}.#{fields[0]} = #{field_or_attr('id', table(main_table,-1))}"
      add_filter "#{table('links')}.relation_id = #{fields[1]}"
      add_filter "#{field_or_attr('id')} = #{table('links')}.#{fields[2]}"
    end

    def insert_after_filter
      if after_filter = context[:after_filter]
        add_filter after_filter
      end
    end
end


class DummyClass
  # Mock connection
  def self.connection; ActiveRecord::Base.connection; end
end