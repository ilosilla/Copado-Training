({
    redirectToURL: function(component, event, helper) {
        var urlToRedirect = component.get("v.urlToRedirect");
        
        // Verificar que se haya especificado una URL
        if (urlToRedirect) {
            // Redirigir al usuario a la URL
            window.location.href = urlToRedirect;
        } else {
            // Manejar el caso en que la URL no esté definida
            console.error("URL no definida");
        }
    }
})