class CreatorsController < ApplicationController
  def registered
    people = Person.with_name(params[:query]).limit(params[:limit] || 10)

    people = people.map do |person|
      { creator_id: person.id,
        affiliation: person.institutions.collect(&:title).join(', '),
        family_name: person.last_name,
        given_name: person.first_name,
        orcid: person.orcid }
    end

    respond_to do |format|
      format.json { render json: people, adapter: nil }
    end
  end

  def unregistered
    creators = AssetsCreator.unregistered.
      select(:creator_id, :given_name, :family_name, :affiliation, :orcid).
      distinct.
      with_name(params[:query]).
      reorder('').
      limit(params[:limit] || 10)

    creators = creators.all.map do |creator|
      { affiliation: creator.affiliation,
        family_name: creator.family_name,
        given_name: creator.given_name,
        orcid: creator.orcid }
    end

    respond_to do |format|
      format.json { render json: creators, adapter: nil }
    end
  end
end
