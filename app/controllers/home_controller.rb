class HomeController < ApplicationController

  def index
  end

  def emite_boletos
    xls_file = params[:file].path
    token = params[:token]
    if token && xls_file
      session['BOLETO_TOKEN'] = params[:token]
      boleto_simples_service = Boleto.new(token)
      @logs = boleto_simples_service.create_from_xls(xls_file)
    else
      flash[:error] = 'Informe o arquivo e o Token'
      redirect_to home_index_path
    end
  rescue => e
    flash[:error] = e.message
    redirect_to home_index_path
  end

  def about
  end

end
