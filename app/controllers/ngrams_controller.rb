class NgramsController < ApplicationController
  layout "ngrams"
  
  def index
  end
  
  def ngram_calculator
    raise 'xhr only' unless request.xhr?
    
    terms = get_terms_from_params
    smoothing_factor = params[:s].blank? ? 1 : params[:s].to_i
    
    hsh = if (err = determine_if_any_errors(terms, smoothing_factor)).present?
      { :error => err }
    else
      QuestionNgram.ngram_query(terms, :smoothing => smoothing_factor)
    end
    
    hsh[:error] = "Something went wrong" if hsh.blank?
    
    render :json => hsh
  end
  
  def search
    raise 'xhr only' unless request.xhr?
    
    terms = get_terms_from_params
    raise 'invalid search terms' if determine_if_any_errors(terms).present?
    
    articles = QuestionNgram.full_text_search(terms, :limit => 5)
    
    render :text => render_to_string(:partial => 'summaries', :locals => {:articles => articles})
  end
  
  def random
    render :json => QuestionNgram.recommended_query_hsh
  end
  
  def tagline
    render :text => Tagline.random
  end
  
  private
  
  def get_terms_from_params
    QuestionNgram.get_terms_from_query_string(params[:q])
  end
  
  def determine_if_any_errors(terms, smoothing_factor = 1)
    if terms.blank?
      "Enter something!"
    elsif terms.size > 8
      "You can't enter more than 8 things!"
    elsif terms.any?{|t| t.is_too_long_to_be_a_valid_query?}
      "Search phrases can't contain more than #{QuestionNgram::MAX_NGRAM_SIZE} words!"
    elsif smoothing_factor < 0 || smoothing_factor > 5
      "Smoothing Factor must be between 0 and 5"
    end
  end
end