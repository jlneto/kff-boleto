class HomeController < ApplicationController

  def index
  end

  def emite_boletos
    xls_file = params[:file].path
    boleto_simples_service = Boleto.new
    @logs = boleto_simples_service.create_from_xls(xls_file)
  rescue => e
    flash[:error] = e.message
    redirect_to home_index_path
  end

  def about
  end

end
