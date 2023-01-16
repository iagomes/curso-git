public without sharing class GetFinancialBalanceApiFromERP {

    @AuraEnabled(cacheable=false)
    public static String getFinancialBalanceByDistributionCenterCode(String distributionCenterCode) {
        try {
            DistributionCenterListHelper distributionCenter = new DistributionCenterListHelper(true);
            FinancialBalance financialBalance = new FinancialBalance(
                distributionCenter.mapCodeToListaCentroDistribuicao.get(distributionCenterCode).CNPJCD__c);
    
            String resultString = IntegrationUtils.sendSyncronousRequestByIntegrationCustomSettings(
                IntegrationConstants.RESERVATION_FINANCIAL_BALANCE_ALT_METADATA, 
                financialBalance.getJSONToSendERPJustWithDistributionCenterCNPJ());
            
            ResponseOutRegioes responseERP = (ResponseOutRegioes)JSON.deserialize(resultString, ResponseOutRegioes.class);
            System.debug('responseERP ==> ' + responseERP);
            if(responseERP.out_Regioes == null) {
                ResponseErrorERP responseError = (ResponseErrorERP)JSON.deserialize(resultString, ResponseErrorERP.class);
                throw new CustomException('Erro ao tentar buscar o saldo financeiro. \n ' + responseError.Message);
            } else {
                ResponseERP[] responseERPNullList = new ResponseERP[]{};
                for(ResponseERP iResponseERP : responseERP.out_Regioes) {
                    if(iResponseERP.IdReservaFin != null) {
                        responseERPNullList.add(iResponseERP);
                    }
                }
                if(responseERPNullList.isEmpty()) {
                    throw new CustomException('Não existe nenhum saldo financeiro para o centro de distribuição escolhido.');
                }
            }

            responseERP.populateAllFieldsResponseERP();

            return JSON.serialize(responseERP);

        } catch(Exception e) {
            throw new CustomException(e.getMessage() + ' \n ');
        }
    }

    public static Response getFinancialBalance(String reserveId) {
        try {
            FinancialBalance financialBalance;
            DistributionCenterListHelper distributionCenter = new DistributionCenterListHelper(true);
            Reserva__c[] reservationList = [
                SELECT Id, CodigoCD__c, RecordType.Name, CodigoSaldoFinanceiro__c 
                FROM Reserva__c 
                WHERE Id =: reserveId 
                LIMIT 1];
            DestinatarioReserva__c[] senderReservationList = [
                SELECT Id, CodigoRegiao__c, Reserva__c, Cliente__c, Cliente__r.CNPJ__c, Cliente__r.CPF__c, Cliente__r.CodigoRegiao__c 
                FROM DestinatarioReserva__c 
                WHERE Reserva__c =: reserveId];
            
                
    
            if(!reservationList.isEmpty()) {
                financialBalance = new FinancialBalance(reservationList[0], senderReservationList, distributionCenter.mapCodeToListaCentroDistribuicao);
            } else {
                throw new CustomException('Reserva não encontrada dentro do Salesforce.');
            }

            String resultString = IntegrationUtils.sendSyncronousRequestByIntegrationCustomSettings(
                IntegrationConstants.RESERVATION_FINANCIAL_BALANCE_ALT_METADATA, 
                financialBalance.getJSONToSendERP());

            ResponseOutRegioes responseERP = (ResponseOutRegioes)JSON.deserialize(resultString, ResponseOutRegioes.class);
            System.debug(financialBalance.getJSONToSendERP());
            if(responseERP.out_Regioes == null) {
                ResponseErrorERP responseError = (ResponseErrorERP)JSON.deserialize(resultString, ResponseErrorERP.class);
                throw new CustomException('Erro ao tentar buscar o saldo financeiro. \n ' + responseError.Message);
            }
    
            return new Response(responseERP.getBalance());
        } catch(Exception e) {
            throw new CustomException(e.getMessage() + ' \n ');
        }
    }

    private class ResponseErrorERP {
        public String Message;
    }

    public class Response {
        public Decimal RefreshedBalance {get; set;}
        public Boolean HaveBalance {get; set;}

        private Response(Decimal refreshedBalance) {
            this.RefreshedBalance = refreshedBalance;
            this.HaveBalance = this.RefreshedBalance != null && this.RefreshedBalance != 0.0 ? true : false;
        }
    }

    private class FinancialBalance {
        public Reserva__c Reservation {get; set;}
        public String distributionCenterCNPJ {get; set;}
        public DestinatarioReserva__c[] SenderReservationList {get; set;}
        public Map<String, ListaCentroDistribuicao__c> MapDistributionCenterCodeToListaCentroDistribuicao {get; set;}

        public FinancialBalance(Reserva__c reservationObject, DestinatarioReserva__c[] senderReservationList, Map<String, ListaCentroDistribuicao__c> mapDistributionCenterCodeToListaCentroDistribuicao) {
            this.Reservation = reservationObject;
            this.SenderReservationList = senderReservationList;
            this.MapDistributionCenterCodeToListaCentroDistribuicao = new Map<String, ListaCentroDistribuicao__c>();
            this.MapDistributionCenterCodeToListaCentroDistribuicao = mapDistributionCenterCodeToListaCentroDistribuicao;
        }

        public FinancialBalance(String distributionCenterCNPJ) {
            this.distributionCenterCNPJ = distributionCenterCNPJ;
        }

        public String getJSONToSendERP() {
            if(!this.MapDistributionCenterCodeToListaCentroDistribuicao.containsKey(this.Reservation.CodigoCD__c)) {
                throw new CustomException('Centro de distribuição inválido ' + this.Reservation.CodigoCD__c + '.');
            } else {
                return JSON.serialize(new SendERP(this.senderReservationList, this.MapDistributionCenterCodeToListaCentroDistribuicao.get(this.Reservation.CodigoCD__c).CNPJCD__c, this.Reservation.RecordType.Name, this.Reservation.CodigoSaldoFinanceiro__c));
            }
        }

        public String getJSONToSendERPJustWithDistributionCenterCNPJ() {
            return JSON.serialize(new SendERP(this.distributionCenterCNPJ));
        }
    }

    private class SendERP {
        public List<Regioes> Regioes = new List<Regioes>();

        public SendERP(DestinatarioReserva__c[] senderReservationList, String filial, String type, String codigoReservaERP) {
            for(DestinatarioReserva__c iDestinatarioReserva : senderReservationList) {
                Regioes regioao = new Regioes(iDestinatarioReserva, filial, type, codigoReservaERP);
                Regioes.add(regioao);
            }
        }

        public SendERP(String distributionCenterCNPJ) {
                Regioes regioao = new Regioes(distributionCenterCNPJ);
                Regioes.add(regioao);
        }
    }

    private class Regioes {
        public String Codigo;
        public String Filial;
        public String IdReservaFin;

        public Regioes(DestinatarioReserva__c sender, String filial, String type, String idFinancialBalanceERP) {
            this.Codigo = '';
            // this.Codigo = type.contains('regional') ? sender.CodigoRegiao__c : sender.Cliente__r.CodigoRegiao__c;
            this.Filial = filial;
            this.IdReservaFin = idFinancialBalanceERP;
        }

        public Regioes(String distributionCenterCNPJ) {
            this.Codigo = '';
            this.IdReservaFin = '';
            this.Filial = distributionCenterCNPJ;
        }
    }

    private class ResponseOutRegioes {
        public List<ResponseERP> out_Regioes = new List<ResponseERP>();

        public Decimal getBalance() {
            Decimal balance = 0;
            for(ResponseERP iResponseERP : out_Regioes) {
                for(RegioesIN iRegioesIN : iResponseERP.Regioes) {
                    balance = balance + iRegioesIN.SaldoFinanceiro;
                }
            }
            return balance;
        }

        public void populateAllFieldsResponseERP() {
            for(ResponseERP iResponseERP : out_Regioes) {
                if(iResponseERP.IdReservaFin != null) {
                    iResponseERP.setTotalFields();

                }
            }
        }
    }

    private class ResponseERP {
        public String IdReservaFin;
        public String TotalRegion = '';
        public Decimal TotalBalance = 0;
        public RegioesIN[] Regioes;
        public Boolean Selected = false;
        public Boolean ShowChields = false;

        public void setTotalFields() {
            List<String> totalRegion = new List<String>();
            this.TotalBalance = 0;
            this.Selected = false;
            this.ShowChields = false;
            for(RegioesIN iRegioesIN : Regioes) {
                if(iRegioesIN.SaldoFinanceiro != null) {
                    this.TotalBalance = this.TotalBalance + iRegioesIN.SaldoFinanceiro;
                    totalRegion.add(iRegioesIN.Codigo);
                }
            }
            this.TotalRegion = String.join(totalRegion, ' | ');
        }
    }

    private class RegioesIN {
        public String Codigo;
        public Decimal SaldoFinanceiro;
        public Boolean RegiaoEncontrada;
    }
}