import { LightningElement, api } from 'lwc';

export default class libPanel extends LightningElement {
  
  ////////////////////////////////////
  // API
  ////////////////////////////////////

  @api showPanel;
  @api title;
  @api icon;

  @api 
    get cssContainerClass() {return this._cssContainerClass};
    set cssContainerClass(value) {
      this._cssContainerClass = value;
      this.setContainerClassString();
    }

  @api 
    get cssPanelClass() {return this._cssPanelClass};
    set cssPanelClass(value) {
      this._cssPanelClass = value;
      this.setPanelClassString();
    }
    
  @api 
    get border() {return this._border};
    set border(value) {
      this._border = this.toBoolean(value);
      this.setPanelClassString();
    }

  @api 
    get shade() {return this._shade};
    set shade(value) {
      this._shade = this.toBoolean(value);
      this.setPanelClassString();
    }


  @api
    get dock() { return this._dock;}
    set dock(value) {
      this._dock = value;
      this.setContainerClassString();
      this.setPanelClassString();
    }

  @api
    get width() { return this._width; }
    set width(value) {
      this._width = value;
      this.setContainerStyle();
    }

  @api
    get modal() { return this._modal;}
    set modal(value) {
      this._modal = this.toBoolean(value);
    }

  //////////////////////////////////////////
  // VARIABLES
  //////////////////////////////////////////

  // API Control variables
  _cssContainerClass = '';
  _cssPanelClass = '';
  _hasBorder = false;  
  _dock = 'right';
  _border=true;
  _shade=false;
  _width='200px';
  _modal=false;

  // Local variables
  containerClass;
  panelClass;
  containerStyle;

  //////////////////////////////////////////
  // HOOKS
  //////////////////////////////////////////

  constructor() {
    super();
    this.setContainerClassString();
    this.setPanelClassString();
    this.setContainerStyle();
    this.showPanel = false;
  }

  setContainerClassString() {
    if (this._dock) {
      this._dock = this._dock.toLowerCase();
    }
    this.containerClass = 'parent-panel dock-' + this._dock + ' ' + this._cssContainerClass;
  }

  setPanelClassString() {
    this.panelClass = 'child-panel ' + this._cssPanelClass;
    if (this._border) {
      if (this._dock == 'left') {
        this.panelClass += ' slds-border_right';
      } else {
        this.panelClass += ' slds-border_left';
      }
    }
    if (this._shade) {
      this.panelClass += ' slds-theme_shade';
    } else {
      this.panelClass += ' white-background';
    }
  }

  setContainerStyle() {
    this.containerStyle = "width: " + this._width + ';';
  }

  toBoolean(val) {
    return (val.toString().toLowerCase() === 'true');
  }

}