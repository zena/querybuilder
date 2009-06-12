class UserProcessor < QueryBuilder::Processor
  self.main_table = 'users'
  self.main_class = 'TestUser'
  
  # Default sort order
  def default_order_clause
    "name asc, first_name asc"
  end
  
  def default_context_filter
    'self'
  end
  
  def process_relation(relation)
    case relation
    when 'objects'  
      this.apply_scope(default_scope) if context[:last]
      add_table('objects')
      @query.add_filter "#{table('objects')}.id = #{field_or_attr('node_id')}"
      change_processor 'DummyProcessor'
    else
      return nil
    end
  end
  
  # Overwrite this and take car to check for valid fields.
  def process_field(field_name)
    if ['id', 'name', 'first_name', 'node_id'].include?(field_name)
      "#{table}.#{field_name}"
    else
      super # raises
    end
  end
end
