module ActiveFedora
  module Associations
    class HasManyAssociation < CollectionAssociation #:nodoc:
      def initialize(owner, reflection)
        super
      end

      # Returns the number of records in this collection.
      #
      # That does not depend on whether the collection has already been loaded
      # or not. The +size+ method is the one that takes the loaded flag into
      # account and delegates to +count_records+ if needed.
      #
      # If the collection is empty the target is set to an empty array and
      # the loaded flag is set to true as well.
      def count_records
        count = if loaded? 
          @target.size
        else
          @reflection.klass.count(:conditions => @counter_query)
          # load_target
          # @target.size
        end

        # If there's nothing in the database and @target has no new records
        # we are certain the current target is an empty array. This is a
        # documented side-effect of the method that may avoid an extra SELECT.
        @target ||= [] and loaded if count == 0

        return count
      end

      def insert_record(record, force = false, validate = true)
        set_belongs_to_association_for(record)
        record.save
      end

      protected

        # Deletes the records according to the <tt>:dependent</tt> option.
        def delete_records(records, method)
          # records.each do |r| 
          #   r.remove_relationship(find_predicate, @owner)
          # end
          #
          if method == :destroy
            records.each { |r| r.destroy }
            update_counter(-records.length) unless inverse_updates_counter_cache?
          else
            # Find all the records that point to this and nullify them
            # keys  = records.map { |r| r[reflection.association_primary_key] }
            # scope = scoped.where(reflection.association_primary_key => keys)

            if method == :delete_all
              raise "Not Implemented"
              #update_counter(-scope.delete_all)
            else

              inverse = reflection.inverse_of.name
              records.each do |record|
                if record.persisted?
                  record.reload
                  assoc = record.association(inverse)
                  if assoc.reflection.collection?
                    # Remove from a has_and_belongs_to_many
                    record.association(inverse).delete(@owner)
                  else
                    # Remove from a belongs_to
                    record.association(inverse).id_writer(nil)
                  end
                  record.save!
                end
              end

              #update_counter(-scope.update_all(reflection.foreign_key => nil))
            end
          end
        end

        
    end
  end
end
