import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
/**
 * @slot profile-menu   Menú de usuario/perfil (fila superior, derecha)
 * @slot cart-icon      Icono de carrito (fila superior, derecha)
 */

export default class B2bServiceHeader extends NavigationMixin(LightningElement) {
    @api title;

    get showTitle() {
        return Boolean(this.title);
    }

    handleHome() {
        this[NavigationMixin.Navigate]({
            type: 'standard__webPage',
            attributes: {
                url: '/'
            }
        });
    }

}