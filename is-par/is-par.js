function isPar(number){
    
    if(number%2==0){
        return true
    }else{
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