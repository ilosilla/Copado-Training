import { LightningElement, api, wire } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

//LABELS
import documentsLabel from '@salesforce/label/c.presources_documentation';
import trainingLabel from '@salesforce/label/c.presources_porcelanosa_campus';
import finderLabel from '@salesforce/label/c.presources_product_finder';
import porsavenueLabel from '@salesforce/label/c.presources_porsavenue';

export default class ShortcutsComponent extends LightningElement {
    registers;
    registersToDisplay;
    componentTitle = 'Shortcuts';

    links = [
        { label: documentsLabel, name: 'resources',description: 'Place where you can find multiple documents to help you', url: '/lightning/o/ContentDocument/home' },
        { label: trainingLabel, name: 'training',description: 'Campus where you can find multiple trainings', url: 'https://campus.porcelanosagrupo.com/v2/' },
        { label: finderLabel, name: 'finder',description: 'Search a product to get all the data about it', url: 'https://productfinder.porcelanosagrupo.com/' },
        { label: porsavenueLabel, name: 'porsavenue',description: 'Search a product to get all the data about it', url: 'https://visitas.porcelanosagrupo.com/' },
    ];

    openUrl(event){
        window.open(event.currentTarget.dataset.linkurl);
    }
}