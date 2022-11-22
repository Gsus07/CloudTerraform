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

    const number = event.queryStringParameters.number;
    const isPrime = isPrime(number);

    return {
        statusCode: 200,
        headers: {
            'Content-Type': 'application/json',
        },
        body: JSON.stringify({
            number,
            isPrime,
        }),
    }
}