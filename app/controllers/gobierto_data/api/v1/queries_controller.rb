# frozen_string_literal: true

module GobiertoData
  module Api
    module V1
      class QueriesController < BaseController

        before_action :authenticate_user!, except: [:index, :show, :meta, :new]
        before_action :allow_author!, only: [:update, :destroy]

        # GET /api/v1/data/queries
        # GET /api/v1/data/queries.json
        # GET /api/v1/data/queries.csv
        # GET /api/v1/data/queries.xlsx
        def index
          respond_to do |format|
            format.json do
              render json: filtered_relation, links: links(:index), adapter: :json_api
            end

            format.csv do
              render_csv(csv_from_relation(filtered_relation, csv_options_params))
            end

            format.xlsx do
              send_data xlsx_from_relation(filtered_relation, name: controller_name.titleize).read, filename: "#{controller_name.underscore}.xlsx"
            end
          end
        end

        # GET /api/v1/data/queries/1
        # GET /api/v1/data/queries/1.json
        # GET /api/v1/data/queries/1.csv
        # GET /api/v1/data/queries/1.xlsx
        def show
          find_item
          query_result = @item.result
          respond_to do |format|
            format.json do
              render(
                json:
                {
                  data: query_result.delete(:result),
                  meta: query_result,
                  links: links(:data)
                },
                adapter: :json_api
              )
            end

            format.csv do
              render_csv(csv_from_query_result(query_result.fetch(:result, ""), csv_options_params))
            end

            format.xlsx do
              send_data xlsx_from_query_result(query_result.fetch(:result, ""), name: @item.name).read, filename: "#{@item.id}.xlsx"
            end
          end
        end

        # GET /api/v1/data/queries/1/meta
        # GET /api/v1/data/queries/1/meta.json
        def meta
          find_item

          render(
            json: @item,
            exclude_links: true,
            links: links(:metadata),
            adapter: :json_api
          )
        end

        # GET /api/v1/data/queries/new
        # GET /api/v1/data/queries/new.json
        def new
          @item = base_relation.new(name_translations: available_locales_hash, user: current_user)

          render(
            json: @item,
            exclude_links: true,
            with_translations: true,
            links: links(:new),
            adapter: :json_api
          )
        end

        # POST /api/v1/data/queries
        # POST /api/v1/data/queries.json
        def create
          @query_form = QueryForm.new(query_params.merge(site_id: current_site.id, user_id: current_user.id))

          if @query_form.save
            @item = @query_form.query
            render(
              json: @item,
              status: :created,
              exclude_links: true,
              with_translations: true,
              links: links(:metadata),
              adapter: :json_api
            )
          else
            api_errors_render(@query_form, adapter: :json_api)
          end
        end

        # PUT /api/v1/data/queries/1
        # PUT /api/v1/data/queries/1.json
        def update
          @query_form = QueryForm.new(query_params.except(*ignored_attributes_on_update).merge(site_id: current_site.id, id: @item.id))

          if @query_form.save
            render(
              json: @query_form.query,
              exclude_links: true,
              with_translations: true,
              links: links,
              adapter: :json_api
            )
          else
            api_errors_render(@query_form, adapter: :json_api)
          end
        end

        # DELETE /api/v1/data/queries/1
        # DELETE /api/v1/data/queries/1.json
        def destroy
          @item.destroy

          head :no_content
        end

        private

        def base_relation
          if find_dataset.present?
            @dataset.queries.open
          else
            current_site.queries.open
          end
        end

        def find_dataset
          @dataset = current_site.datasets.find_by(id: params[:dataset_id])
        end

        def query_params
          ActiveModelSerializers::Deserialization.jsonapi_parse(params, only: [:dataset_id, :name_translations, :name, :privacy_status, :sql])
        end

        def filter_params
          params.fetch(:filter, {}).permit(:user_id, :dataset_id)
        end

        def filtered_relation
          base_relation.where(filter_params)
        end

        def find_item
          @item = base_relation.unscope(where: :privacy_status).find(params[:id])
        end

        def links(self_key = nil)
          id = @item&.id
          {
            index: gobierto_data_api_v1_queries_path(filter: filter_params),
            new: new_gobierto_data_api_v1_query_path,
            visualizations: gobierto_data_api_v1_visualizations_path
          }.tap do |hash|
            if id.present?
              hash.merge!(
                data: gobierto_data_api_v1_query_path(id),
                metadata: meta_gobierto_data_api_v1_query_path(id),
                visualizations: gobierto_data_api_v1_visualizations_path(filter: { query_id: id })
              )
            end

            hash[:self] = hash.delete(self_key) if self_key.present?
          end
        end

        def ignored_attributes_on_update
          [:dataset_id, :user_id]
        end

        def allow_author!
          find_item
          render(json: { message: "Unauthorized" }, status: :unauthorized, adapter: :json_api) && return if @item.user != current_user
        end

      end
    end
  end
end
