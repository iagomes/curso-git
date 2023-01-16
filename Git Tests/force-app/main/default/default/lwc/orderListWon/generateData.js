export default function generateData({ amountOfRecords }) {
    return [...Array(amountOfRecords)].map((_, index) => {
        return {
            OrderNumber : Math.floor(Math.random() * 1000),
            AccountName: `Name (${index})`,
            EffectiveDate: new Date(
                Date.now() + 86400000 * Math.ceil(Math.random() * 20)
            ),
            TotalAmount: Math.floor(Math.random() * 100),
            Status: 'Em Digitação'            
        };
    });
}