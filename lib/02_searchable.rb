require_relative 'db_connection'
require_relative '01_sql_object'
require 'byebug'
module Searchable
  def where(params)
    where_line = params.map { |key,val| "#{self.table_name}.#{key.to_s} = ?"}
    vals = params.map {|key, val| params[key]}
    where_line = where_line.join(" AND ")

    thing = DBConnection.execute(<<-SQL, *vals)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{where_line}
    SQL

    parse_all(thing)
  end
end

class SQLObject
  extend Searchable
end
