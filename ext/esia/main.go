package main

import "C"

import (
	crand "crypto/rand"

	"crypto/x509"
	"encoding/base64"
	"encoding/pem"
	"fmt"
	"math/rand"
	"net/url"
	"os"
	"strings"
	"time"

	"github.com/Theo730/gogost/gost3410"
	"github.com/Theo730/gogost/gost34112012256"
	"github.com/Theo730/pkcs7"
)

type Esia struct {
	ClientID string
	Scopes   string
	Key      *gost3410.PrivateKey
	Cert     *x509.Certificate
}

func (esia Esia) SignMessage(message string) (signedMessage string, err error) {
	hasher := gost34112012256.New()

	_, err = hasher.Write([]byte(message))
	if err != nil {
		return "", err
	}

	dgst := hasher.Sum(nil)

	var prvKey gost3410.PrivateKeyReverseDigest = gost3410.PrivateKeyReverseDigest{}
	prvKey.Prv = esia.Key

	signature, err := prvKey.Sign(crand.Reader, dgst, nil)
	if err != nil {
		return "", err
	}

	signedData, err := pkcs7.NewSignedData()
	if err != nil {
		return "", fmt.Errorf("Cannot initialize signed data: %v", err)
	}

	err = signedData.AddSigner(esia.Cert, esia.Key, signature)
	if err != nil {
		return "", fmt.Errorf("Cannot add signer: %v", err)
	}

	data, err := signedData.Finish()
	if err != nil {
		return "", fmt.Errorf("Cannot signing data: %v", err)
	}

	return base64.RawURLEncoding.EncodeToString(data), nil
}

func getState() string {
	rand.Seed(time.Now().UnixNano())

	return fmt.Sprintf(
		"%04X%04x-%04x-%04x-%04x-%04x%04x%04x",
		rand.Int31n(65000),
		rand.Int31n(65000),
		rand.Int31n(65000),
		rand.Int31n(65000)|0x4000,
		rand.Int31n(65000)|0x8000,
		rand.Int31n(65000),
		rand.Int31n(65000),
		rand.Int31n(65000),
	)
}

func getData() string {
	tm := time.Now()

	return tm.Format("2006.01.02 15:04:05 -0700")
}

func getMessage(esia Esia, strTime string, state string) string {
	return fmt.Sprintf(
		"%s%s%s%s",
		esia.Scopes,
		strTime,
		esia.ClientID,
		state,
	)
}

//export create_client_secret
func create_client_secret(client_id *C.char, scopes *C.char, secret_key_path *C.char, cerificate_path *C.char) (result *C.char) {
	var esia Esia
	esia.ClientID = C.GoString(client_id)
	esia.Scopes = C.GoString(scopes)

	pkey, err := os.ReadFile(C.GoString(secret_key_path))
	if err != nil {
		return combineResult("", "", "", fmt.Sprintf("Error open key file %v %v", err, C.GoString(secret_key_path)))
	}

	blockPkey, _ := pem.Decode(pkey)
	if blockPkey == nil || blockPkey.Type != "PRIVATE KEY" {
		return combineResult("", "", "", "failed to decode PEM block containing private key ")
	}

	key, err := pkcs7.ParsePKCS8PrivateKey(blockPkey.Bytes)
	if err != nil {
		return combineResult("", "", "", err.Error())
	}
	esia.Key = key

	ckey, err := os.ReadFile(C.GoString(cerificate_path))
	if err != nil {
		return combineResult("", "", "", fmt.Sprintf("Error open cert file %v %v", err, C.GoString(cerificate_path)))
	}

	blockCkey, _ := pem.Decode(ckey)
	if blockCkey == nil || blockCkey.Type != "CERTIFICATE" {
		return combineResult("", "", "", "failed to decode PEM block containing certificate")
	}

	cert, err := x509.ParseCertificate(blockCkey.Bytes)
	if err != nil {
		return combineResult("", "", "", err.Error())
	}
	esia.Cert = cert
	esia.Scopes = strings.ReplaceAll(esia.Scopes, ",", "")

	state := getState()
	data := getData()
	message := getMessage(esia, data, state)
	clientSecret, err := esia.SignMessage(message)

	if err != nil {
		return combineResult("", "", "", err.Error())
	}

	data = url.QueryEscape(data)

	return combineResult(clientSecret, state, data, "")
}

func combineResult(clientSecret string, state string, data string, err string) *C.char {
	return C.CString(fmt.Sprintf(
		"{ \"client_secret\": \"%s\", \"state\": \"%s\", \"timestamp\": \"%s\", \"error\": \"%s\" }",
		clientSecret,
		state,
		data,
		err,
	))
}

// Test it
func main() {
	result := create_client_secret(
		C.CString("TEAM"),
		C.CString("fullname"),
		C.CString("./private_key.pem"),
		C.CString("./certificate.pem"),
	)

	fmt.Println(C.GoString(result))
}
