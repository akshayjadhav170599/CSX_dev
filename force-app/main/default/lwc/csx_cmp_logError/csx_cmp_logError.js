import addApexLog from '@salesforce/apex/CSX_CMP_LoggerUtility.addClientErrorLog';

export function csx_cmp_logError(className, methodName, error, parameters) {

    let msg = '';
    let exptype = '';
    console.log('error from log error:  ', error);
    if (error.name) {
        exptype = error.name;
        msg = error.message;
    } else {
        exptype = error.errorType;
        msg = JSON.stringify(error);
    }
    addApexLog({
        className: className,
        methodName: methodName,
        error: JSON.stringify(error),
        parameters: parameters
    })
        .then(result => {
        }).catch(error => {
            if (error) {
                console.log(error);
            }
        });
}