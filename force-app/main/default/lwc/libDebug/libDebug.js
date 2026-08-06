import { LightningElement } from 'lwc';

/**
 * =========================================================
 * libDebug
 * ---------------------------------------------------------
 * Reusable read-only debug helpers for LWC components.
 *
 * Responsibilities:
 * - Build serializable snapshots from a component instance
 * - Read a single value from a component path
 * - Print readable state to the browser console
 * - Expose a reusable public debug facade for components
 * - Emit optional console.debug traces behind a browser storage flag
 *
 * Design notes:
 * - This module is read-only by design.
 * - It does not mutate component state.
 * - Components may expose the facade through a small public getter such as __debug.
 * =========================================================
 */

const DEFAULT_EXCLUDED_PROPERTIES = ['template', 'refs', 'labels', 'errors'];
const DEFAULT_EXCLUDED_COMPUTED_PROPERTIES = ['isDebugEnabled', 'debugOptions', '__debug'];
const DEFAULT_FLAG_NAME = 'debug.lwc';

function getDebugOptions(component, options = {}) {
    const componentName = options.componentName ?? component?.constructor?.name ?? 'Component';

    return {
        componentName: componentName,
        flagName: options.flagName ?? DEFAULT_FLAG_NAME,
        includeComputed: options.includeComputed !== false,
        excludeProperties: [
            ...DEFAULT_EXCLUDED_PROPERTIES,
            ...(options.excludeProperties ?? [])
        ],
        excludeComputedProperties: [
            ...DEFAULT_EXCLUDED_COMPUTED_PROPERTIES,
            ...(options.excludeComputedProperties ?? [])
        ]
    };
}

function sortPlainObjectKeys(objectValue) {
    const sortedObject = {};
    const keys = Object.keys(objectValue ?? {}).sort();

    for (const key of keys) {
        sortedObject[key] = objectValue[key];
    }

    return sortedObject;
}

function serializeDebugValue(value, visited) {
    if (value === null || value === undefined) {
        return null;
    }

    if (
        typeof value === 'string'
        || typeof value === 'number'
        || typeof value === 'boolean'
    ) {
        return value;
    }

    if (typeof value === 'bigint') {
        return String(value);
    }

    if (typeof value === 'function') {
        return '[Function]';
    }

    if (value instanceof Date) {
        return value.toISOString();
    }

    if (value instanceof Map) {
        const mapObject = {};
        const entries = Array.from(value.entries()).sort((leftEntry, rightEntry) => {
            return String(leftEntry[0]).localeCompare(String(rightEntry[0]));
        });

        for (const entry of entries) {
            mapObject[String(entry[0])] = serializeDebugValue(entry[1], visited);
        }

        return mapObject;
    }

    if (value instanceof Set) {
        return Array.from(value.values()).map(item => serializeDebugValue(item, visited));
    }

    if (Array.isArray(value)) {
        return value.map(item => serializeDebugValue(item, visited));
    }

    if (typeof value === 'object') {
        if (visited.has(value)) {
            return '[Circular]';
        }

        visited.add(value);

        const result = {};
        const keys = Object.keys(value).sort();

        for (const key of keys) {
            try {
                result[key] = serializeDebugValue(value[key], visited);
            } catch (ex) {
                result[key] = {
                    propertyError: true,
                    message: ex?.message ?? String(ex)
                };
            }
        }

        visited.delete(value);
        return result;
    }

    return {
        nonSerializable: true,
        type: typeof value,
        stringValue: String(value)
    };
}

function toSerializableDebugValue(value) {
    if (value === undefined) {
        return null;
    }

    return serializeDebugValue(value, new Set());
}

function shouldIncludeDebugProperty(propertyName, options) {
    if (!propertyName) {
        return false;
    }

    if (options.excludeProperties.includes(propertyName)) {
        return false;
    }

    if (propertyName.startsWith('__')) {
        return false;
    }

    return true;
}

function shouldIncludeDebugComputedProperty(propertyName, options) {
    if (!propertyName || propertyName === 'constructor') {
        return false;
    }

    if (propertyName.startsWith('__')) {
        return false;
    }

    if (
        propertyName.startsWith('getDebug')
        || propertyName.startsWith('printDebug')
        || propertyName === 'getDebugOptions'
    ) {
        return false;
    }

    if (options.excludeComputedProperties.includes(propertyName)) {
        return false;
    }

    return true;
}

function collectDebugStatefulPropertyNames(component) {
    const propertyNames = new Set();
    let prototype = Object.getPrototypeOf(component);

    while (prototype && prototype !== LightningElement.prototype) {
        const names = Object.getOwnPropertyNames(prototype);

        for (const propertyName of names) {
            const descriptor = Object.getOwnPropertyDescriptor(prototype, propertyName);
            if (!descriptor) {
                continue;
            }

            if (typeof descriptor.set === 'function') {
                propertyNames.add(propertyName);
            }
        }

        prototype = Object.getPrototypeOf(prototype);
    }

    return Array.from(propertyNames).sort();
}

function collectDebugInstanceProperties(component, options) {
    const state = {};
    const propertyNames = new Set();
    const ownPropertyNames = Object.getOwnPropertyNames(component).sort();
    const statefulPropertyNames = collectDebugStatefulPropertyNames(component);

    for (const propertyName of ownPropertyNames) {
        propertyNames.add(propertyName);
    }

    for (const propertyName of statefulPropertyNames) {
        propertyNames.add(propertyName);
    }

    const sortedPropertyNames = Array.from(propertyNames).sort();

    for (const propertyName of sortedPropertyNames) {
        if (!shouldIncludeDebugProperty(propertyName, options)) {
            continue;
        }

        state[propertyName] = toSerializableDebugValue(component[propertyName]);
    }

    return sortPlainObjectKeys(state);
}

function collectDebugComputedProperties(component, options) {
    const computed = {};
    let prototype = Object.getPrototypeOf(component);

    while (prototype && prototype !== LightningElement.prototype) {
        const propertyNames = Object.getOwnPropertyNames(prototype).sort();

        for (const propertyName of propertyNames) {
            const descriptor = Object.getOwnPropertyDescriptor(prototype, propertyName);
            if (!descriptor || typeof descriptor.get !== 'function') {
                continue;
            }

            if (typeof descriptor.set === 'function') {
                continue;
            }

            if (!shouldIncludeDebugComputedProperty(propertyName, options)) {
                continue;
            }

            if (computed[propertyName] !== undefined) {
                continue;
            }

            try {
                computed[propertyName] = toSerializableDebugValue(component[propertyName]);
            } catch (ex) {
                computed[propertyName] = {
                    getterError: true,
                    message: ex?.message ?? String(ex)
                };
            }
        }

        prototype = Object.getPrototypeOf(prototype);
    }

    return sortPlainObjectKeys(computed);
}

function buildDebugUnderline(length) {
    return ''.padEnd(length, '=');
}

function toCompactDebugJson(value) {
    const serializedValue = toSerializableDebugValue(value);
    const jsonValue = JSON.stringify(serializedValue);
    return jsonValue ?? 'null';
}

function printDebugSectionToConsole(title, section) {
    const keys = Object.keys(section ?? {}).sort();
    const paddingSize = Math.max(...keys.map(key => key.length), 0);

    console.info('%c' + title, 'font-weight:bold;font-family:monospace;');
    console.info(buildDebugUnderline(title.length));

    if (keys.length === 0) {
        console.info('<none>');
        console.info('');
        return;
    }

    for (const key of keys) {
        const paddedKey = (key + ':').padEnd(paddingSize + 1, ' ');
        console.info(
            '%c' + paddedKey + '%c ' + toCompactDebugJson(section[key]),
            'font-weight:bold;font-family:monospace;',
            'font-weight:normal;font-family:monospace;'
        );
    }

    console.info('');
}


function buildDebugFacade(component, options = {}) {
    const debugOptions = getDebugOptions(component, options);

    return {
        isEnabled() {
            return isDebugEnabled(component, debugOptions);
        },

        enable(persistent = false) {
            try {
                if (persistent === true) {
                    window.localStorage.setItem(debugOptions.flagName, '1');
                } else {
                    window.sessionStorage.setItem(debugOptions.flagName, '1');
                }
            } catch (ex) {
                console.warn(
                    '[' + debugOptions.componentName + '] Unable to enable debug mode.',
                    ex
                );
            }

            return isDebugEnabled(component, debugOptions);
        },

        disable() {
            try {
                window.sessionStorage.removeItem(debugOptions.flagName);
                window.localStorage.removeItem(debugOptions.flagName);
            } catch (ex) {
                console.warn(
                    '[' + debugOptions.componentName + '] Unable to disable debug mode.',
                    ex
                );
            }

            return false;
        },

        getState(includeComputed = true) {
            return getState(component, {
                ...debugOptions,
                includeComputed: includeComputed !== false
            });
        },

        printState(includeComputed = true) {
            printState(component, {
                ...debugOptions,
                includeComputed: includeComputed !== false
            });
        },

        getValue(path) {
            return getValue(component, path);
        }
    };
}

export function getState(component, options = {}) {
    const debugOptions = getDebugOptions(component, options);
    const snapshot = {
        __debug: {
            component: debugOptions.componentName,
            flagName: debugOptions.flagName,
            label: options.label ?? null,
            includeComputed: debugOptions.includeComputed
        },
        __state: collectDebugInstanceProperties(component, debugOptions)
    };

    if (debugOptions.includeComputed) {
        snapshot.__computed = collectDebugComputedProperties(component, debugOptions);
    }

    if (options.extra !== undefined) {
        snapshot.__extra = toSerializableDebugValue(options.extra);
    }

    return snapshot;
}

export function printState(component, options = {}) {
    const snapshot = getState(component, options);

    printDebugSectionToConsole('INSTANCE VARIABLES (this)', snapshot.__state);

    if (snapshot.__computed) {
        printDebugSectionToConsole('GETTERS', snapshot.__computed);
    }

    if (snapshot.__extra) {
        printDebugSectionToConsole('EXTRA', snapshot.__extra);
    }
}

export function getValue(component, path) {
    if (!path) {
        return null;
    }

    const segments = path.split('.');
    let currentValue = component;

    for (const segment of segments) {
        if (currentValue === null || currentValue === undefined) {
            return null;
        }
        currentValue = currentValue[segment];
    }

    return toSerializableDebugValue(currentValue);
}

export function isDebugEnabled(component, options = {}) {
    try {
        const flagName = getDebugOptions(component, options).flagName;
        return window.sessionStorage.getItem(flagName) === '1'
            || window.localStorage.getItem(flagName) === '1';
    } catch (ex) {
        return false;
    }
}

export function getFacade(component, options = {}) {
    return buildDebugFacade(component, options);
}

export function debugExpose(component, label, extra = {}, options = {}) {
    const debugOptions = getDebugOptions(component, options);
    if (!isDebugEnabled(component, debugOptions)) {
        return;
    }

    console.debug(
        '[' + debugOptions.componentName + ']',
        getState(component, {
            ...debugOptions,
            label: label,
            extra: extra,
            includeComputed: true
        })
    );
}