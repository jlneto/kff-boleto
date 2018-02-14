require 'boletosimples'
require 'roo'

class Boleto

  def initialize(token)
    BoletoSimples.configure do |c|
      c.environment = ENV['BOLETOSIMPLES_ENV'].to_sym
      c.access_token = (token || ENV['BOLETOSIMPLES_ACCESS_TOKEN'])
    end
  end

  def create_from_xls(xls_file_path)
    workbook = Roo::Spreadsheet.open(xls_file_path, extension: :xlsx)
    workbook.default_sheet = workbook.sheets[0]
    boletos = []
    ((workbook.first_row + 1)..workbook.last_row).each do |row|
      cep = workbook.row(row)[7].to_s
      phone = workbook.row(row)[5].to_s.try(:gsub,'(','').try(:gsub,')','')
      boletos << {
          description: workbook.row(row)[0],
          amount: workbook.row(row)[1],
          expire_at: workbook.row(row)[2],
          customer_person_name: workbook.row(row)[3],
          customer_cnpj_cpf: workbook.row(row)[4],
          customer_phone_number: phone,
          customer_email: workbook.row(row)[6],
          customer_zipcode: cep,
          customer_address: workbook.row(row)[8],
          customer_address_number: workbook.row(row)[9],
          customer_address_complement: workbook.row(row)[10],
          customer_neighborhood: workbook.row(row)[11],
          customer_city_name: workbook.row(row)[12],
          customer_state: ('SP' ||  workbook.row(row)[14]),
          customer_person_type: 'individual',
      }
    end

    log = []
    boletos.each do |boleto|
      creation_log = create( boleto )
      log << creation_log if creation_log
      sleep 0.1
    end

    log
  end

  # Criar um boleto passando os dados dos clientes
  # Não vamos salvar clientes pois os dados podem mudar
  def create(boleto_hash)
    bank_billet = BoletoSimples::BankBillet.create(boleto_hash)
    if bank_billet.persisted?
      response = nil #bank_billet.attributes
    else
      response = bank_billet.response_errors
      response[:dados_informados] = boleto_hash
    end
    puts response if response
    response
  rescue => e
    puts e.message
    e.message
  end


end