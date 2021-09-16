# Validation Messages and Error Handling

## Learning Goals

- Display validation messages on the frontend
- Use HTTP status codes to interpret server response

## Introduction

In previous lessons, we learned how to use Active Record to perform server-side
validations. Now, let's see how we can use those error messages to display
useful information to our users so they can submit valid data.

To get the backend set up, run:

```console
$ bundle install
$ rails db:migrate db:seed
$ rails s
```

Then, in a new terminal, run the frontend:

```console
$ npm install --prefix client
$ npm start --prefix client
```

Confirm both applications are up and running by visiting
[`localhost:4000`](http://localhost:4000) and viewing the list of movies in your
React application.

## Writing Server-Side Validations

Let's start by adding some validations to our `Movie` model:

```rb
class Movie < ApplicationRecord
  CATEGORIES = ['Comedy', 'Drama', 'Animation', 'Mystery', 'Horror', 'Fantasy', 'Action', 'Documentary', 'Science Fiction']

  validates :title, presence: true
  validates :year, numericality: {
    greater_than_or_equal_to: 1888,
    less_than_or_equal_to: Date.today.year
  }
  validates :poster_url, presence: true
  validates :category, inclusion: {
    in: CATEGORIES,
    message: "must be one of: #{CATEGORIES.join(', ')}"
  }

end
```

We can also update our controller action to check the validity of our model when
it is created, and respond appropriately:

```rb
def create
  movie = Movie.create!(movie_params)
  render json: movie, status: :created
rescue ActiveRecord::RecordInvalid => e
  render json: { errors: e.record.errors.full_messages }, status: :unprocessable_entity
end
```

Now, in the browser, try to submit the form with some invalid data. Use the
Network tab to view the response from the server. You should see that we are
successfully returning the validation errors and the status code from this
request:

![network 422 errors](https://curriculum-content.s3.amazonaws.com/phase-4/validation-messages-and-error-handling/network-422-error.png)

Now that we have the error messages back from the server, how can we show them
to our users so that they know how to fix them?

## Displaying Validation Errors

Let's focus on the React side of things. There are now two possible options when
we submit the form. Either we get a **good response** indicating that the form
data was saved successfully, or a **bad response** indicating that something
went wrong with our request. So, we need to:

- Check if we got a good response or a bad response
- If we got a bad response:
  - Save the error messages in state
  - Display the errors to our user
- If we got a good response:
  - Navigate the user to the home page to show them their newly created movie

Let's take things one step at a time. First: **Check if we got a good response
or a bad response**.

In the `MovieForm` component's `handleSubmit` function, modify the fetch request
as follows:

```js
fetch("/movies", {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify(formData),
}).then((response) => console.log(response));
```

Next, try submitting the form with invalid data again and take a look at the
response object that is logged in the console:

![fetch bad response](https://curriculum-content.s3.amazonaws.com/phase-4/validation-messages-and-error-handling/bad-fetch-response.png)

We can use the `.ok` property of the `response` object to see whether the
response has a good status code (200-300 range) or a bad status code (400-500
range) and handle the response accordingly. If the response is not ok, we'll want
to display some error messages to the user; that means we'll need to keep track
of those error messages in state, and re-render the component when those error
messages are updated:

```js
function MovieForm() {
  const [errors, setErrors] = useState([]);
  // rest of component code
}
```

```js
.then((response) => {
  if (response.ok) {
    response.json().then((newMovie) => console.log(newMovie));
  } else {
    response.json().then((errorData) => setErrors(errorData.errors));
  }
})
```

We'll also want to [conditionally display][inline-if] the errors in the JSX
being returned from our component:

```jsx
// In the JSX returned by MovieForm:

<form onSubmit={handleSubmit}>
  {/* rest of form elements here... */}

  {errors.length > 0 && (
    <ul style={{ color: "red" }}>
      {errors.map((error) => (
        <li key={error}>{error}</li>
      ))}
    </ul>
  )}
  <SubmitButton type="submit">Add Movie</SubmitButton>
</form>
```

Now the user should see the error messages on the form when it doesn't pass our
validations on the server!

## Bonus: Refactoring with async/await

You may notice the code for the `fetch` request in its entirety is a bit hard to
read:

```js
function handleSubmit(e) {
  e.preventDefault();
  fetch("/movies", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(formData),
  }).then((response) => {
    if (response.ok) {
      response.json().then((newMovie) => console.log(newMovie));
    } else {
      response.json().then((errorData) => setErrors(errorData.errors));
    }
  });
}
```

In particular, working with the `response` object and the Promise chaining
required to read the JSON data from the response isn't particularly elegant.

One way we can clean this up is using the [`async/await`][async-await] syntax:

```js
// make the function async to enable the await keyword
async function handleSubmit(e) {
  e.preventDefault();
  // fetch returns a Promise, we must await it
  const response = await fetch("/movies", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(formData),
  });
  // response.json() returns a Promise, we must await it
  const data = await response.json();
  if (response.ok) {
    console.log("Movie created:", data);
  } else {
    setErrors(data.errors);
  }
}
```

This code better expresses our function's intent when it comes to working with
the response. Our server will always send back JSON data, so we always want to
parse the response; and after we've parsed the response, we can decide what to
do with that data based on whether or not the response was `ok`.

## Conclusion

To handle server-side validations, we can leverage Active Record to check our
model's validity before saving bad data to the database. We can also send back
different response data with different status codes from our controller actions
based on the validity of our data.

To help our users correct these validation errors, we need to show them the
error messages from the server. We can write some conditional code to handle
successful vs unsuccessful responses from the server. In a React application, we
can then use state to hold the error messages and render them somewhere on the
form using JSX.

## Check For Understanding

Before you move on, make sure you can answer the following questions:

1. How can we differentiate between a successful and unsuccessful response using
   `fetch`?
2. Why might it be important to display validation error messages to our users?

## Resources

- [Using Fetch](https://developer.mozilla.org/en-US/docs/Web/API/Fetch_API/Using_Fetch#checking_that_the_fetch_was_successful)
- [async/await][async-await]

[async-await]: https://javascript.info/async-await
[inline-if]: https://reactjs.org/docs/conditional-rendering.html#inline-if-with-logical--operator
