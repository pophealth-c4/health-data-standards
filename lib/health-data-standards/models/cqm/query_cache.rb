module HealthDataStandards
  module CQM
    class QueryCache
      include Mongoid::Document
      store_in collection: 'query_cache'

      field :measure_id, type: String
      field :sub_id, type: String
      field :population_ids, type: Hash
      field :effective_date, type: Integer
      field :IPP, type: Integer
      field :DENOM, type: Integer
      field :NUMER, type: Integer
      field :antinumerator, type: Integer
      field :DENEX, type: Integer
      field :DENEXCEP, type: Integer
      field :MSRPOPL, type: Integer

      def self.aggregate_measure(measure_id, effective_date)
        cache_entries = self.where(effective_date: effective_date, measure_id: measure_id)
        aggregate_count = AggregateCount.new
        aggregate_count.measure_id = measure_id
        cache_entries.each do |cache_entry|
          if cache_entry.is_stratification?
            stratification = Stratification.new
            stratification.populations = cache_entry.build_populations
            stratification.id = cache_entry.population_ids['stratification']
            aggregate_count.stratifications << stratification
          else
            aggregate_count.top_level_populations = cache_entry.build_populations
          end
        end
        aggregate_count
      end

      def is_stratification?
        population_ids.has_key?('stratification')
      end

      def build_populations
        populations = []
        population_ids.each do |population_type, population_id|
          unless population_type == 'stratification'
            population = Population.new
            population.type = population_type
            population.id = population_id
            population.value = self[population_type]
            populations << population
          end
        end
        populations
      end
    end
  end
end