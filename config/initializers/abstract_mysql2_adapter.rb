# patch to allow Rails 3 to setup db on mySQL 5.7 - which introduced the restriction that creating PRIMARY KEY columns as NULL will produce an error
# https://jira-bsse.ethz.ch/browse/OPSK-857
class ActiveRecord::ConnectionAdapters::Mysql2Adapter
  NATIVE_DATABASE_TYPES[:primary_key] = "int(11) auto_increment PRIMARY KEY"
end