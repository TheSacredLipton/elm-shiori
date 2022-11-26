//@flow
/**
 * TDOO: カリー化は一旦諦めた
 */
/*::
type just<T> = {type: 'Just', value: T}
type nothing = {type: 'Nothing'}
export type Maybe<T> = just <T> | nothing
*/

const Just = /*::<T>*/ (value /*:T */) /*:just<T> */ => ({ type: 'Just', value })
const Nothing = () /*:nothing */ => ({ type: 'Nothing' })

const withDefault = /*::<T>*/ (defaultValue /*:T */, maybe /*:Maybe<T> */) /*:T */ => {
  if (maybe.type === 'Just') {
    return maybe.value
  } else {
    return defaultValue
  }
}

/*::
type Map<A,B> = A => B
*/
const map = /*::<A,B> */ (f /*:Map<A,B> */, maybe /*:Maybe<A> */) /*:Maybe<B> */ => {
  if (maybe.type === 'Just') {
    return Just(f(maybe.value))
  } else {
    return Nothing()
  }
}

/*::
type AndThen<A,B> = A => Maybe<B>
 */
const andThen = /*::<A,B> */ (f /*:AndThen<A,B> */, maybe /*:Maybe<A> */) /*:Maybe<B> */ => {
  if (maybe.type === 'Just') {
    return f(maybe.value)
  } else {
    return Nothing()
  }
}

const values = /*::<T>*/ (maybeList /*:Maybe<T>[] */) /*: T[] */ => {
  return []
}

const combine = /*::<T>*/ (maybeList /*:Maybe<T>[] */) /*: Maybe<T[]> */ => {
  return Nothing()
}

const isJust = /*::<T>*/ (maybe /*:Maybe<T> */) /*:boolean */ => {
  return maybe.type === 'Just'
}

const aaa /*:Maybe<number> */ = Nothing()

module.exports = {
  Just,
  Nothing,
  withDefault,
  map,
  andThen,
  isJust
}
