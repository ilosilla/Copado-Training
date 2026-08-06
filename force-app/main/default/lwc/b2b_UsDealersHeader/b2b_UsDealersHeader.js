import { LightningElement,api } from 'lwc';
import topLinksJson from '@salesforce/resourceUrl/B2B_USDealersTopLinks';
/**
 * @slot profile-menu   Menú de usuario/perfil (fila superior, derecha)
 * @slot cart-icon      Icono de carrito (fila superior, derecha)
 * @slot logo           Logo de la marca (fila central, izquierda)
 * @slot search-bar     Barra de búsqueda (fila central, derecha)
 * @slot main-navigation Menú de navegación principal (fila inferior)
 */
export default class B2b_UsDealersHeader extends LightningElement {

    @api showTopBar = false;
    @api showNavigationBar = false;
    
    topLinks = [];

    connectedCallback() {
        fetch(topLinksJson)
            .then((response) => response.json())
            .then((data) => {
                this.topLinks = data;
            })
        .catch((error) => {
            console.error('Error loading top links:', error);
        });
    }

}