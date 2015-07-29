require_relative 'db_connection'
require 'active_support/inflector'
require 'byebug'

class SQLObject
  def self.columns
    query = DBConnection.execute2(<<-SQL)
      SELECT
        *
      FROM
        #{self.table_name}
    SQL

    columns = query[0]
    columns.map {|col| col.to_sym}
  end



  def self.finalize!

    columns.each do |col|
      define_method("#{col}=") do |arg|
        attributes[col] = arg
      end


      define_method("#{col}") do
        attributes[col]
      end
    end
  end



  def self.table_name=(table_name)
    @table_name = table_name
  end

  def self.table_name
    if @table_name == nil
      return self.to_s.tableize
    end

    @table_name
  end

  def self.all

    results = DBConnection.execute(<<-SQL)
    SELECT
      *
    FROM
      #{self.table_name}
    SQL

    self.parse_all(results)

  end

  def self.parse_all(results)
    things = []
    results.each do |hash|
      things << self.new(hash)
    end
    things
  end

  def self.find(id)
    result_array = DBConnection.execute(<<-SQL, id)
      SELECT
        *
      FROM
        #{self.table_name}
      WHERE
        #{self.table_name}.id  = ?
      SQL

      return nil if result_array.length == 0
    self.new(result_array.first)
  end

  def initialize(params = {})
    params.each do | key, value |
      if self.class.columns.include?(key.to_sym)
        self.send(:"#{key}=", value)
      else
        raise "unknown attribute \'#{key}\'"
      end
    end
  end

  def attributes
    @attributes ||= {}
  end

  def attribute_values
    self.class.columns.map {|key| self.send(key)}
  end

  def insert
    col_names = self.class.columns.join(",")
    question_marks = (["?"] * self.class.columns.count).join(",")
    params = self.attribute_values

    DBConnection.execute(<<-SQL, *params)
      INSERT INTO
        #{self.class.table_name} (#{col_names})
      VALUES
        (#{question_marks})
      SQL

      self.id = DBConnection.last_insert_row_id

  end

  def update
    set_line = self.class.columns.map {|key| "#{key.to_s} = ?"}
    set_line_no_id = set_line.drop(1)
    final_set_line = set_line_no_id.join(",")
    params = self.attribute_values.drop(1)

    DBConnection.execute(<<-SQL, *params)
      UPDATE
        #{self.class.table_name}
      SET
        #{final_set_line}
      WHERE
        id = #{self.id}
    SQL
  end

  def save
    if self.id == nil
      self.insert
    else
      self.update
    end
  end
end
