function isPar(number){
    var numero = 11;
    
    if(numero%2==0){
        alert("El número "+numero+" es par");
        return true
    }else{
        alert("El número "+numero+" es impar");
        return false
    }
}

    module.exports.handler = async (event) => {
        console.log('Event: ', event);
    
        if (event.queryStringParameters && event.queryStringParameters['number']) {
            const number = parseInt(event.queryStringParameters['number']);
            const result = isPar(number);
    
            return {
                statusCode: 200,
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({
                    number,
                    isPar: result,
                }),
            }
        }
    
        return {
            statusCode: 400,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                message: 'Missing number parameter',
            }),
        }    
}