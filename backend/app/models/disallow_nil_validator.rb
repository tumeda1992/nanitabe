class DisallowNilValidator < ActiveModel::EachValidator
  def validate_each(record, attr_name, value)
    record.errors.add(attr_name, "がnilです") if value.nil?
  end
end
