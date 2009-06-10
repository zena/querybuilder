class DummyProcessor < NewQueryBuilder::Processor
  self.main_table = "objects"
  self.main_class = 'DummyClass'

  def default_scope
    'self'
  end

  # Scope current context with previous context. 
  # For example:
  #                          current         previous
  #  ['parent_id', 'id'] ==> no1.parent_id = nodes.id
  def scope_fields(scope, is_last = false)
    case scope
    when 'self'
      ['parent_id', 'id']
    when 'parent'
      is_last ? ['parent_id', 'parent_id'] : ['parent_id', 'id']
    when 'project'
      is_last ? ['project_id', 'project_id'] : ['project_id', 'id']
    when 'site', main_table
      # not an error, but do not scope
      []
    else
      # error
      nil
    end
  end

  # Overwrite this and take car to check for valid fields.
  def process_field(fld_name)
    if ['id', 'parent_id', 'project_id', 'section_id', 'kpath', 'name', 'event_at', 'custom_a'].include?(fld_name)
      "#{table}.#{fld_name}"
    else
      super # raises an error
    end
  end

  def process_relation(relation)
    unless class_relation(relation) || context_relation(relation) || direct_filter(relation) || join_relation(relation)
      super # raise an error
    end
  end

  private
    def class_relation(relation)
      case relation
      when 'users'  
        add_table('users')
        add_table(main_table)
        @query.add_filter "#{table('users')}.node_id = #{field_or_attr('id')}"
        this.apply_scope(default_scope) if context[:last]
        change_processor 'UserProcessor'
        return true
      else
        return nil
      end
    end  

    def context_relation(relation)
      case relation
      when 'self'
        fields = ['id', 'id']
      when 'parent'
        fields = ['id', 'parent_id']
      when 'project'
        fields = ['id', 'project_id']
      when main_table, 'children'
        context[:scope] ||= default_scope
        add_table(main_table)
        return true # dummy clause: does nothing
      else
        return false
      end
    
      add_table(main_table)
      @query.add_filter "#{field_or_attr(fields[0])} = #{field_or_attr(fields[1], table(main_table,-1))}"
    end

    # Direct filter
    def direct_filter(relation)
      case relation
      when 'letters'
        context[:scope] ||= default_scope
        add_table(main_table)
        @query.add_filter "#{table}.kpath LIKE 'NNL%'"
      when 'clients'
        context[:scope] ||= default_scope
        add_table(main_table)
        @query.add_filter "#{table}.kpath LIKE 'NRCC%'"
      else
        return false
      end
    end

    # Filters that need a join
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
      @query.add_filter "#{field_or_attr('id')} = #{table('links')}.#{fields[2]} AND #{table('links')}.relation_id = #{fields[1]} AND #{table('links')}.#{fields[0]} = #{field_or_attr('id', table(main_table,-1))}"
    end

end
