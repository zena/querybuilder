class TestUser
  def self.connection; self; end
  def self.quote(obj)
    obj.kind_of?(String) ? "'#{obj}'" : obj
  end
end

class UserProcessor < QueryBuilder::Processor
  set_main_table 'users'
  set_main_class 'TestUser'
  set_default    :order,   'name asc, first_name asc'
  set_default    :context, 'self'

  def process_relation(relation)
    case relation
    when 'objects'
      this.apply_scope(default(:scope)) if context[:last]
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
