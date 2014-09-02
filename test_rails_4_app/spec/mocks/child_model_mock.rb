require 'active_mocker/mock'

class ChildModelMock < UserMock

  class << self

    def attributes
      @attributes ||= HashWithIndifferentAccess.new({}).merge(super)
    end

    def types
      @types ||= ActiveMocker::Mock::HashProcess.new({  }, method(:build_type)).merge(super)
    end

    def associations
      @associations ||= {:accounts=>nil}.merge(super)
    end

    def mocked_class
      'ChildModel'
    end

    private :mocked_class

    def attribute_names
      @attribute_names ||= [] | super
    end

    def primary_key
      "id"
    end

    def abstract_class?
      false
    end

  end

  ##################################
  #   Attributes getter/setters    #
  ##################################

  def id
    read_attribute(:id)
  end

  def id=(val)
    write_attribute(:id, val)
  end

  ##################################
  #         Associations           #
  ##################################


# has_many
  def accounts
    @associations[:accounts] ||= ActiveMocker::Mock::HasMany.new([],foreign_key: 'child_model_id', foreign_id: @attributes['id'], relation_class: classes('Account'), source: '')
  end

  def accounts=(val)
    @associations[:accounts] ||= ActiveMocker::Mock::HasMany.new(val, foreign_key: 'child_model_id', foreign_id: @attributes['id'], relation_class: classes('Account'), source: '')
  end

  module Scopes
    include UserMock::Scopes

    def by_credits(credits)
      ActiveMocker::LoadedMocks.find('ChildModel').send(:call_mock_method, 'by_credits', credits)
    end

  end

  extend Scopes

  class ScopeRelation < ActiveMocker::Mock::Association
    include ChildModelMock::Scopes
  end

  private

  def self.new_relation(collection)
    ChildModelMock::ScopeRelation.new(collection)
  end

  public

  ##################################
  #        Model Methods           #
  ##################################


  def child_method
    call_mock_method :child_method
  end

  private

  def self.reload
    load __FILE__
  end

end