import { api, track } from 'lwc';
//libraries
import momentJS from '@salesforce/resourceUrl/momentJS';
import momentTimezone from '@salesforce/resourceUrl/momentTimezone';
import LwcUtils from 'c/lwcUtils';
import LANG from '@salesforce/i18n/lang';
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
//APEXCLASSES
import getHours from '@salesforce/apex/NBK_AppointmentManager.getAvailableHours';
import getAvailableDays from '@salesforce/apex/NBK_AppointmentManager.getAvailableDays';
import getHourList from '@salesforce/apex/NBK_AppointmentManager.getHourList';
import IsOpened from '@salesforce/apex/NBK_AppointmentManager.IsOpened';
// import getCache from '@salesforce/apex/NBK_AppointmentManager.getCache';
// import saveCache from '@salesforce/apex/NBK_AppointmentManager.saveCache';
//LABELS
import appointmentSelectDate from '@salesforce/label/c.appointmentSelectDate';
import appointmentFullyBooked from '@salesforce/label/c.appointmentFullyBooked';
import todayButton from '@salesforce/label/c.NBK_todayButton';
import prevButton from '@salesforce/label/c.NBK_prevButton';
import nextButton from '@salesforce/label/c.NBK_nextButton';
import selectByHour from '@salesforce/label/c.NBK_selectByHour';
import selectByDay from '@salesforce/label/c.NBK_selectByDay';
import availableHours from '@salesforce/label/c.NBK_availableHours';
import {FlowNavigationBackEvent,FlowNavigationNextEvent} from "lightning/flowSupport";


export default class nBK_appointmentDatePicker extends LwcUtils {

	@api businessHours;
	@api breakHours;
	@api selectedStore;
	@api dateFormat = 'YYYY-MM-DD';
	@api comercialId;
	@api comercialEmail;
	@api selectedDateTime;
	@api currentSelectedDateTime;
	@api endDateTime;
	@api confirmHours = false;
	@api warehouseCountry;
	@api fechaHoraStr;
	@track selectTime = false;
	//input labels
	// @api todayButtonLabel = 'Today';
	// @api prevButtonLabel = 'Prev';
	// @api nextButtonLabel = 'Next';

	label = {
        appointmentSelectDate,
        appointmentFullyBooked,
		todayButton,
		prevButton,
		nextButton,
		selectByDay,
		selectByHour,
		availableHours
	};

    //private
	lastClass;
	today;
	weekDays;
	timezone;

	@track selectedDate;
	@track dateContext;
	@track dates = [];
	@track showSpinnerHours = false;
	@track showToastBar = false;
	workingDays = [];
	openedDaysMap = [];

	availableHours = [];
	hourList;
	value = '';
	showAvailableHours = false;
	emptyAvailableHours = true;
	calendarMode = 'daySelected';
	hourAvailableDays = [];
	selectedHour;
	showCalendarHoursMode = false;
	showHoursCombobox = false;
	defaultModeValue = 'daySelected';

	selectModeOptions = [{label: this.label.selectByHour,  value: 'hourSelected'},
						 {label: this.label.selectByDay, value: 'daySelected'}];


    get formattedSelectedDate() {
		return this.selectedDate ? this.selectedDate.format(this.dateFormat) : '';
	}
	get year() {
		return this.dateContext.format('Y');
	}
	get month() {
		const urlParams = new URLSearchParams(window.location.search);
		const lang = urlParams.get("language")?.toLowerCase() || 'en_gb';

		// Mapear country → locale
		const localeMap = {
			'fr': 'fr',
			'es': 'es',
			'en_gb': 'en-GB',
			'de': 'de'
		};

		const locale = localeMap[lang] || 'en-GB';

		const formatter = new Intl.DateTimeFormat(locale, { month: 'long' });
		return this.capitalize(formatter.format(this.dateContext));
	}
	get validDates() {
		return this._validDates;
	}
	get emptyAvailableHours(){
		return available;
	}
	get showHourList(){
		return this.hourList != null ? true : false;
	}

	get showAvailableDates(){
		return this.calendarMode === "daySelected" ? true : false;
	}

	sendDateTimeInfoToGtm() {
        document.dispatchEvent(
            new CustomEvent("ma_step_2", 
            { "detail" : 
                { 
                    event: "ma_step_2",
                    appointment_category: "make an appointment form",
                    appointment_action: "2_confirm_store",
                    appointment_label: this.selectedStore.Name
                 }
            })
        );
    }

	handleBack() {
				const navigateBackEvent = new FlowNavigationBackEvent();
				this.dispatchEvent(navigateBackEvent);
	}
	handleNext() {
			this.sendDateTimeInfoToGtm();
				const navigateNextEvent = new FlowNavigationNextEvent();
				this.dispatchEvent(navigateNextEvent);

	}

	async daysSituation () {
		let daysToCheck = [];
		const start = this.dateContext.clone().startOf('month');
    	const end = this.dateContext.clone().endOf('month');
		let current = start.clone();

		while (current.isSameOrBefore(end)) {
			daysToCheck.push(current.toDate());
			current.add(1, 'day');
		}

		let days = daysToCheck.map(d =>
			moment(d).format("YYYY-MM-DD")
		);	

		try{
			console.log('BUSSINESS HOURS')
			console.log(JSON.parse(this.businessHours).Id)
			console.log(JSON.stringify(days))
			const result=await IsOpened({
        		businessHoursId: JSON.parse(this.businessHours).Id,
        		days: days
			});
					
			this.openedDaysMap = result;
			return result;
		}catch(error){
			console.error('Error IsOpened', error);
		};
	}

    connectedCallback() {
		try{
			this.timezone = this.businessHours.TimeZoneSidKey;

			this.businessHours = JSON.stringify(this.businessHours);
			this.breakHours = JSON.stringify(this.breakHours);
			let self = this;
			this.showSpinner = true;
			super.loadResources({scripts: [momentJS]})
			.then(() => {
				self.calculateWeekEnd();
				self.initDates(self);
				super.loadResources({scripts: [momentTimezone]})
				.then(() => {})
				.catch((e) => { console.error(e); });
				self.getHoursList();
				})
			.catch((e) => { console.error(e); });
		}catch(e){console.error(e);}
	}

	calculateWeekEnd(){
		let bHours = JSON.parse(this.businessHours);
		let workDays = [];
		if(bHours.MondayStartTime != null){
			workDays.push('Monday');
		}
		if(bHours.TuesdayStartTime != null){
			workDays.push('Tuesday');
		}
		if(bHours.WednesdayStartTime != null){
			workDays.push('Wednesday');
		}
		if(bHours.ThursdayStartTime != null){
			workDays.push('Thursday');
		}
		if(bHours.FridayStartTime != null){
			workDays.push('Friday');
		}
		if(bHours.SaturdayStartTime != null){
			workDays.push('Saturday');
		}
		if(bHours.SundayStartTime != null){
			workDays.push('Sunday');
		}
		this.workingDays = workDays;
	}
	initDates(self) {
		const urlParams = new URLSearchParams(window.location.search);
		const lang = urlParams.get("language")?.toLowerCase() || 'en_gb';

		// Mapear country → locale
		const localeMap = {
			'fr': 'fr',
			'es': 'es',
			'en_gb': 'en-GB',
			'de': 'de'
		};

		const locale = localeMap[lang] || navigator.language || 'en-gb';

		moment.locale(locale);

		self.today = moment();
		self.weekDays = self.getWeekDays(self.today);

		self.dateContext = self.today;

		self.showSpinner = false;
		self.refreshDateNodes();
	}

    getWeekDays(momentDate){
		let self = this;
		return momentDate
			.localeData()
			.weekdaysShort()
			.map(day => {
				day = day.replace('.', '');
				return self.capitalize(day);
			});
	}

    capitalize(str){
		return str[0].toUpperCase() + str.slice(1);
	}

    previousMonth() {
		this.dateContext = moment(this.dateContext).subtract(1, 'month');
		this.refreshDateNodes();
	}

    nextMonth() {
		this.dateContext = moment(this.dateContext).add(1, 'month');
		this.refreshDateNodes();
	}

	goToday() {
		this.dateContext = this.today;
		this.refreshDateNodes();
	}

	changeSelectedDate(selection, self){
		this.showAvailableHours = false;
		this.confirmHours = false;
		self.selectedDate = selection;
		self.getAvailableHours();
	}
	getHoursList(){
		this.availableHours = [];
		getHourList({selectedDay : moment(), actualBusinessHours : this.businessHours, actualBreakHours : this.breakHours})
            .then((result) =>{
				//console.log("getHoursList: "+JSON.stringify(result));
				if (result != null){
					this.hourList = result;
					//console.log("getHoursList in: "+JSON.stringify(this.hourList));

				}
            })
            .catch((error) =>{
				console.log('ERROR' + JSON.stringify(error));
            })
	}

	getAvailableHours(){
		this.availableHours = [];
		getHours({storeInfo: this.selectedStore, selectedDay : this.selectedDate, actualBusinessHours : this.businessHours, actualBreakHours : this.breakHours})
            .then((result) =>{
				if (result != null){
					this.availableHours = result;
					this.emptyAvailableHours = true;
					let thisContext = this;

					this.availableHours.forEach(function(item) {
						if(item.isEnabled){
							thisContext.emptyAvailableHours = false;
						}
					});
					this.showAvailableHours = true;
					this.showSpinnerHours = false;
				} else {
					this.emptyAvailableHours = true;
					this.showAvailableHours = true;
					this.showSpinnerHours = false;
				}
            })
            .catch((error) =>{
				this.showAvailableHours = false;
				console.log('ERROR' + JSON.stringify(error));
				this.showSpinnerHours = false;
            })
	}

    setSelected(e) {
		this.showSpinnerHours = true;
		console.log('**** setSelected ****');
		const selectedDate = this.template.querySelector('.selected');
		console.log('selectedDate:'+selectedDate);
		if (selectedDate) {
			selectedDate.className = this.lastClass;
		}
		this.lastClass = e.target.className;
		e.target.className = 'selected';

		if(this.calendarMode === 'daySelected'){

			const { date } = e.target.dataset;
			this.changeSelectedDate(moment.parseZone(date), this);
			this.dateContext = moment.parseZone(date);

		}else if (this.calendarMode === 'hourSelected'){

			// console.log("dataset: "+e.target.dataset);
			// console.log("dataset: "+JSON.stringify(e.target.dataset));
			// let newDate = e.target.dataset.date + 'T' + this.selectedHour;
			this.selectedDate = moment.parseZone(e.target.dataset.date);
			// console.log('SELECTED DATE ' + this.selectedDate);
			this.dateContext = moment.parseZone(e.target.dataset.date);

			this.selectAppointmentInfo(e);
		}

	}

	selectHourAppointment(event){
		 console.log("entra a selectHourAppointment");
		this.showSpinnerHours = true;
		this.selectedHour = event.target.value;
		this.selectedHour = this.selectedHour.substring(0,12);

		 console.log("selectedHour: "+this.selectedHour);

		let today = moment();
		console.log('today:'+today);

		this.availableHours = [];
		getAvailableDays({storeInfo: this.selectedStore, selectedHourString : this.selectedHour, selectedDay : today, actualBusinessHours : this.businessHours, warehouseCountry : this.warehouseCountry})
            .then((result) =>{

				if (result != null){

					//this.calendarMode = 'hourSelected';
					this.hourAvailableDays = result;
					// console.log("this.hourAvailableDays: "+JSON.stringify(this.hourAvailableDays));

					this.refreshDateNodes();
					this.showCalendarHoursMode = true;
					this.showSpinnerHours = false;
				}
            })
            .catch((error) =>{
				this.calendarMode = 'daySelected';
				console.log('ERROR' + JSON.stringify(error));
				this.showSpinnerHours = false;
            })

	}

	selectAppointmentInfo(e){
		console.log('***** selectAppointmentInfo *****');
		this.confirmHours = true;
		let selectedHour;
		let selectedHourMinutes;
		this.comercialId = e.target.dataset.id;
		this.comercialEmail = e.target.dataset.email;
		// console.log("this.comercialId: "+this.comercialId);
		// console.log("this.comercialEmail: "+this.comercialEmail);
		console.log('SELETED TIME HOUR')
		console.log(e.target.value)
		if(this.calendarMode === 'daySelected'){
			selectedHour = e.target.value.substring(0,2);
			selectedHourMinutes = e.target.value.substring(0,8);
			// console.log('selectAppointmentInfo selectedHour DayMode: '+selectedHour);

			// console.log('datetime without timezone: ' + moment(this.selectedDate).format());


		} else if(this.calendarMode === 'hourSelected'){
			// console.log('selectAppointmentInfo selectedHour hourMode: '+this.selectedHour);
			selectedHour = this.selectedHour.substring(0,2);
			selectedHourMinutes = this.selectedHour.substring(0,8);
			// console.log('selectAppointmentInfo selectedHour substring: '+selectedHour);


			// this.comercialId = e.target.dataset.id;
			// this.comercialEmail = e.target.dataset.email;
			// console.log("this.comercialId: "+this.comercialId);
			// console.log("this.comercialEmail: "+this.comercialEmail);


			//Obtener el dia seleccionado en formato YYYY-MM-DDD y añadirle T hora y Z y asignarlo a selectedDateTime
		}
		let dateTimezone = this.selectedDate.clone().tz(this.timezone);
		let offset = dateTimezone.utcOffset();

		//let datetime = dateTimezone.add(-(Math.abs(offset)),'minutes');
		let datetime = dateTimezone;

		this.selectedDateTime = datetime.add(selectedHour,'hours');

		this.endDateTime = moment(this.selectedDateTime).add(1, 'hours');

		if (this.selectedDateTime!=null){
				this.selectTime = true;
		}
		try{

			var fechaHora = this.selectedDateTime.format().substring(0,10);
			fechaHora = fechaHora + ' '+selectedHourMinutes
			this.fechaHoraStr = fechaHora;

		}catch(error){
			console.log('Error transformacion fecha');
this.showSpinnerHours = false;
		}
this.showSpinnerHours = false;
	}

    async refreshDateNodes() {
		this.dates = [];
		// startOf mutates moment, hence clone before use
		const start = this.dateContext.clone().startOf('month');
		const end = this.dateContext.clone().endOf('month');
		// months do not always have the same number of weeks. eg. February
		const numWeeks = Math.ceil(end.clone().endOf('week').diff(start.clone().startOf('week'),'weeks',true));
		const daysToCheck = this.openedDaysMapNormalized = Object.entries(await this.daysSituation())
							.reduce((acc, [dateStr, isOpen]) => {
								const key = new Date(dateStr).toISOString().split('T')[0];
								acc[key] = isOpen;
								return acc;
							}, {});

		for (let index = 0; index < numWeeks; index++) {
			Array(7)
				.fill(0)
				.forEach((n, i) => {
					const day = start
						.clone()
						.startOf('week')
						.add(i + 7 * index, 'day');
					let className = '';
					let formatted = '';
					let text = '';
					let comercialId = '';
					let comercialEmail = '';
					let key = day.format('MM') + '-' + day.format('DD');
					if (day.month() === this.dateContext.month()) {
						let isWorkingDay;
						if(this.calendarMode === 'daySelected'){
							for(let d of this.workingDays){
								if(d == day.format('dddd')){
									isWorkingDay = true;
									break;
								} else {
									isWorkingDay = false;
								}
							}
							let dayFormat = moment(day).format("YYYY-MM-DD");
								
							if (daysToCheck[dayFormat] === false) {								
								isWorkingDay = false;
							}
						}else if (this.calendarMode === 'hourSelected'){
							isWorkingDay = false;
							//recorrer lista dias con comerciales disponibles
							let dayFormat = moment(day).format("YYYY-MM-DD");
							// console.log("calendarMode  dayFormat: "+dayFormat);

							for(let d of this.hourAvailableDays){
							// console.log("calendarMode  d.value: "+d.value);

								if(d.isEnabled && d.value == dayFormat){
									isWorkingDay = true;
									comercialEmail = d.comercialEmail;
									comercialId = d.idComercial;
								}
							}
							let notDayOff = false;
							for(let d of this.workingDays){
								if(d == day.format('dddd')){
									notDayOff = true;
								}
							}
							if (!notDayOff){
								isWorkingDay = false;
							}							
							if (daysToCheck[dayFormat] === false) {								
								isWorkingDay = false;
							}	
						}

						if (!isWorkingDay) {
							className = 'disabled ';
						} else if (day.isBefore(this.today, 'day')) {
							className += 'disabled ';
						} else if (day.isSame(this.today, 'day')) {
							className += 'today ';
						} else if (this.selectedDate && day.isSame(this.selectedDate, 'day')) {
							className += 'selected ';
						} else {
							className += 'date ';
						}
						formatted = day.format(this.dateFormat);
						text = day.format('DD');
					} else {
						className = 'disabled';
					}

					
					this.dates.push({
						className,
						formatted,
						text,
						key,
						comercialId,
						comercialEmail
					});
				});
		}
	}

	handleChangeCalendarMode(e){
		this.selectedDate = null;
this.selectTime = false;
		// console.log('CHANGE MODE: ' + e.target.value);
		this.calendarMode = e.target.value;
		if(this.calendarMode === 'hourSelected'){
			this.showCalendarHoursMode = false;
			this.showHoursCombobox = true;
		} else {
			this.showHoursCombobox = false;
		}
		this.showAvailableHours = false;
		this.refreshDateNodes();
	}

}