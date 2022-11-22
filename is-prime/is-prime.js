function isPrime(number) {
    if (number <= 1) {
        return false;
    }

    for (let i = 2; i < number; i++) {
        if (number % i === 0) {
            return false;
        }
    }

    return true;
}


module.exports.handler = async (event) => {
    console.log('Event: ', event);

    if (event.queryStringParameters && event.queryStringParameters['number']) {
        const number = parseInt(event.queryStringParameters['number']);
        const result = isPrime(number);

        return {
            statusCode: 200,
            headers: {
                'Content-Type': 'application/json',
            },
            body: JSON.stringify({
                number,
                isPrime: result,
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