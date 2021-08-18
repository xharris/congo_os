export type ObjectAny<T = any> = {[key:string]:T}

type IStringifyJson = (
  data: ObjectAny,
  options?: {
    language?:string,
    equals?:string,
    array?:[string,string],
    key?:{
      [key:string]: (key:string) => string 
    }
    value?:{ 
      [key:string]: (key:string) => string 
    },
    array_width?:ObjectAny<number>
  }
) => string

type IArrayFill = {
  (length:number, value: any): any[];
  (array:any[], value: any, start?: number, end?: number): any[];
}

const ArrayFill:IArrayFill = (array:number|any[], value:any, start?:number, end?:number) => {
if (Array.isArray(array))
  [start, end] = [start ?? 0, end ?? array.length]
else
  [array, start, end] = [[], start ?? 0, end ?? array]
  
for (let i = start; i < end; i++)
  array[i] = value
return array
}

export const stringifyJSON:IStringifyJson = (data, options) => {
  if (options.language === "lua") {
    options = {
      equals: '=',
      array: ['{','}'],
      key: {
        number: k => `[${k}]`
      },
      value: {
        string: k => `"${k}"`
      },
      ...options
    }
  }

  const { 
    equals=':',
    array=['[',']'],
    key={},
    value={},
    array_width={}
  } = options

  const _stringify = (data:any, depth=1, from=""):string => {
    const indent = ArrayFill(depth, '    ').join('')
    const indent_lessone = ArrayFill(Math.max(0, depth-1), '    ').join('')
    const type = typeof data
    const inline = !!array_width[from]
    const newline = inline ? ' ' : '\n'

    const next_from = (k:string) => from.length > 0 ? `${from}.${k}` : k

    switch (type) {
      case "object":
        if (Array.isArray(data)) {
          if (data.length === 0)
            return `${array[0]}${array[1]}`
          else if (!array_width[from] && data.some(d => typeof d === "object")) {
            const arr = Object.values(data).map((v, i) => 
              `${Array.isArray(data) && i !== 0 ? indent : ''}${_stringify(v, depth+1, from)}`
            )
            return `${array[0]}\n${indent}${arr.join(',\n')}\n${indent_lessone}${array[1]}`
          } else {
            const arr = Object.values(data).map((v) => _stringify(v, typeof v === "object" ? depth+1 : 0, from))
            let new_arr = []
            for (let i = 0, j = arr.length; i < j; i += array_width[from]) {
              new_arr.push(indent + arr.slice(i, i + array_width[from]).join(','))
            }
            return `${array[0]}\n${new_arr.join(',\n')}\n${indent_lessone}${array[1]}` 
          }
        } else if (Object.keys(data).length === 0)
            return "{}"
        else 
          return `{${newline}${Object.entries(data).filter(([_, v]) => v != undefined).map(([k,v]) => 
            `${inline ? '' : indent}${key[typeof k] ? key[typeof k](k) : k} ${equals} ${_stringify(v, depth+1, next_from(k))}`
            ).join(`, ${newline}`)}${newline}${inline ? '' : indent_lessone}}`
      case "number":
        if (!isFinite(data))
            return "\"Inf\""
        else if (isNaN(data))
            return "\"NaN\""
        return value[type] ? value[type](data) : data 
      case "string":
        return `"${string.gsub(data, "\"", '\\"')}"`
      case "boolean":
        return data ? "true" : "false"
      default:
        return "null"
    }
  }
  
  return _stringify(data)
}