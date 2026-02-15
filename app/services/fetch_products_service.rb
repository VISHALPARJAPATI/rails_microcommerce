# frozen_string_literal: true

class FetchProductsService
  ALLOWED_SORT_COLUMNS = %w[name price created_at].freeze
  DEFAULT_SORT = "created_at"
  DEFAULT_ORDER = "desc"
  DEFAULT_PER_PAGE = 10
  MAX_PER_PAGE = 100

  Result = Struct.new(:products, :total_count, :total_pages, :current_page, :per_page, keyword_init: true)

  def initialize(params = {})
    params = params.to_h.with_indifferent_access
    @query = params[:q].to_s.strip
    @sort = params[:sort].presence_in(ALLOWED_SORT_COLUMNS) || DEFAULT_SORT
    @order = params[:order].to_s.downcase == "asc" ? "asc" : "desc"
    @page = [params[:page].to_i, 1].max
    raw_per_page = params[:per_page].to_s == "" ? nil : params[:per_page].to_i
    @per_page = if raw_per_page.nil? || raw_per_page.zero?
      DEFAULT_PER_PAGE
    else
      [[raw_per_page, 1].max, MAX_PER_PAGE].min
    end
  end

  def call
    relation = Product.includes(:category)
    relation = apply_search(relation)
    total_count = relation.distinct.count
    relation = apply_sort(relation)
    relation = apply_pagination(relation)
    total_pages = (total_count.to_f / @per_page).ceil

    Result.new(
      products: relation,
      total_count: total_count,
      total_pages: total_pages,
      current_page: @page,
      per_page: @per_page
    )
  end

  private

  def apply_search(relation)
    return relation if @query.blank?

    relation.where(
      "products.name LIKE :q OR products.description LIKE :q",
      q: "%#{Product.sanitize_sql_like(@query)}%"
    )
  end

  def apply_sort(relation)
    relation.order(@sort => @order)
  end

  def apply_pagination(relation)
    relation.offset((@page - 1) * @per_page).limit(@per_page)
  end
end
