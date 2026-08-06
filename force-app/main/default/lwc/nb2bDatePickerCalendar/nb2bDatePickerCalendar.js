import { api, track } from 'lwc';
import momentJS from '@salesforce/resourceUrl/momentJS';
import LwcUtils from 'c/lwcUtils';
import LANG from '@salesforce/i18n/lang';

export default class Nb2bDatePickerCalendar extends LwcUtils {
	//input variables
	@api actualSelection;
	@api
	set validDates(value){
		this._validDates = value;
	}
	@api dateformat;// = 'YYYY-MM-DD';
	//input labels
	@api todayButtonLabel = 'Today';
	@api prevButtonLabel = 'Prev';
	@api nextButtonLabel = 'Next';

	//private
	lastClass;
	today;
	weekDays;
	_validDates;
	showSpinner;
	
	@track selectedDate;
	@track dateContext;
	@track dates = [];

	get formattedSelectedDate() {
		return this.selectedDate ? this.selectedDate.format(this.dateformat) : '';
	}
	get year() {
		return this.dateContext.format('Y');
	}
	get month() {
		return this.capitalize(this.dateContext.format('MMMM'));
	}
	get validDates() {
		return this._validDates;
	}

	connectedCallback() {
		try{
			let self = this;
			this.showSpinner = true;
			super.loadResources({scripts: [momentJS]})
			.then(() => {
				self.initDates(self);
			})
			.catch((e) => { console.error(e); }); 
		}catch(e){console.error(e);}
	}

	initDates(self){
		moment.updateLocale(LANG, {
			week: {
			  dow : 1, // Monday is the first day of the week.
			},
			weekdaysShort : 'Mon,Tue,Wed,Thu,Fri,Sat,Sun'.split(','),
		  });
		self.today = moment().locale(LANG);
		
		self.weekDays = self.getWeekDays(self.today);
		////console.log("array days: "+self.weekDays);
		if(self.actualSelection){
			let auxDate = moment(self.actualSelection, this.dateformat).locale(LANG);
			self.changeSelectedDate(auxDate, self);
			self.dateContext = auxDate;
		} else {
			self.dateContext = self.today;
		}
		self.showSpinner = false;
		self.refreshDateNodes();
	}

	getWeekDays(momentDate){
		let self = this;
		return momentDate
			.localeData()
			.weekdaysShort(false)
			.map(day => {
				day = day.replace('.', '');
				return self.capitalize(day);
			});
	}
	
	capitalize(str){
		return str[0].toUpperCase() + str.slice(1);
	}

	changeSelectedDate(selection, self){
		self.selectedDate = selection;
		super.fireEvent('selection',self.selectedDate);
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

	@api
	setSelected(e) {
		const selectedDate = this.template.querySelector('.selected');
		if (selectedDate) {
			selectedDate.className = this.lastClass;
		}
		const { date } = e.target.dataset;
        console.log('Nb2bDatePickerCalendar - setSelected() - date:', date);
		this.changeSelectedDate(moment.utc(date), this);
		this.dateContext = moment(date);
		this.lastClass = e.target.className;
		e.target.className = 'selected';
	}

	refreshDateNodes() {
		this.dates = [];
		// startOf mutates moment, hence clone before use
		const start = this.dateContext.clone().startOf('month');
		const end = this.dateContext.clone().endOf('month');
		// months do not always have the same number of weeks. eg. February
		const numWeeks = Math.ceil(end.clone().endOf('week').diff(start.clone().startOf('week'),'weeks',true));
		for (let index = 0; index < numWeeks; index++) {
			Array(7)
				.fill(0)
				.forEach((n, i) => {
					const day = start
						.clone()
						.startOf('week')
						.add(i + 7 * index, 'day');
					//console.log('index ' + index);
					//console.log('I ' + i);
					//console.log('DAY ' + day);
					let formula = i + 7 * index;
					//console.log('FORMULA ' + formula);
					let className = '';
					let formatted = '';
					let text = '';
					let key = day.format('MM') + '-' + day.format('DD');
					if (day.month() === this.dateContext.month()) {
						if (this._validDates && !this._validDates.includes(day.format(this.dateformat))) {
							className = 'disabled ';
						}
						if (day.isSame(this.today, 'day')) {
							className += 'today';
						} else if (this.selectedDate && day.isSame(this.selectedDate, 'day')) {
							className += 'selected';
						} else {
							className += 'date';
						}
						formatted = day;
						// formatted = day.format(this.dateformat);
						text = day.format('DD');
					} else {
						className = 'disabled';
					}
					this.dates.push({
						className,
						formatted,
						text,
						key
					});
				});
		}
	}
}